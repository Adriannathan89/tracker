use super::*;
use chrono::{DateTime, Utc};
use rust_decimal::Decimal;

pub(crate) async fn load_record(conn: &impl ConnectionTrait, id: Uuid) -> AppResult<Record> {
    let r = required(
        conn,
        statement("SELECT * FROM records WHERE id=$1", vec![(id).into()]),
    )
    .await
    .map_err(db_error)?;
    let categories=conn.query_all_raw(statement("SELECT c.* FROM categories c JOIN record_categories rc ON rc.category_id=c.id WHERE rc.record_id=$1 ORDER BY c.kind,c.name", vec![(id).into()])).await.map_err(db_error)?.iter().map(|c|Ok(Category{id:value(c,"id")?,name:value(c,"name")?,kind:value(c,"kind")?})).collect::<AppResult<Vec<_>>>()?;
    Ok(Record {
        id,
        title: value(&r, "title")?,
        description: value(&r, "description")?,
        amount: value(&r, "amount")?,
        kind: value(&r, "kind")?,
        created_at: value::<DateTime<Utc>>(&r, "created_at")?,
        is_committed: value(&r, "is_committed")?,
        categories,
    })
}
async fn set_categories(
    conn: &impl ConnectionTrait,
    id: Uuid,
    primary: &str,
    secondary: &str,
) -> AppResult<()> {
    conn.execute_raw(statement(
        "DELETE FROM record_categories WHERE record_id=$1",
        vec![(id).into()],
    ))
    .await
    .map_err(db_error)?;
    for (name, kind) in [(primary, "primary"), (secondary, "secondary")] {
        let n=conn.execute_raw(statement("INSERT INTO record_categories(record_id,category_id) SELECT $1,id FROM categories WHERE name=$2 AND kind=$3", vec![(id).into(), (name).into(), (kind).into()])).await.map_err(db_error)?;
        if n.rows_affected() != 1 {
            return Err(DomainError::Validation("Category not found".into()));
        }
    }
    Ok(())
}
#[async_trait]
impl RecordRepository for PgStore {
    async fn create_record(
        &self,
        user: Uuid,
        c: CreateRecord,
        p: Classification,
    ) -> AppResult<Record> {
        amount(c.amount)?;
        let id = Uuid::new_v4();
        let tx = self.database.begin().await.map_err(db_error)?;
        let secondary = if self
            .classifier
            .validate_categories(&p.category, &p.secondary_category)
            .is_ok()
        {
            p.secondary_category
        } else {
            p.category.clone()
        };
        self.classifier
            .validate_categories(&p.category, &secondary)?;
        tx.execute_raw(statement("INSERT INTO records(id,owner_id,title,description,amount,kind,created_at) VALUES($1,$2,$3,$4,$5,$6,$7)", vec![(id).into(), (user).into(), (c.title).into(), (c.description).into(), (c.amount).into(), (p.kind).into(), (c.date.and_hms_opt(0,0,0).ok_or_else(||DomainError::Validation("Invalid date".into()))?.and_utc()).into()])).await.map_err(db_error)?;
        set_categories(&tx, id, &p.category, &secondary).await?;
        let r = load_record(&tx, id).await?;
        tx.commit().await.map_err(db_error)?;
        Ok(r)
    }
    async fn list_records(&self, user: Uuid) -> AppResult<RecordOverview> {
        // Consistent overview: records and all balances share one repeatable-read snapshot.
        let tx = self.database.begin().await.map_err(db_error)?;
        tx.execute_raw(statement(
            "SET TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY",
            vec![],
        ))
        .await
        .map_err(db_error)?;
        let u = required(
            &tx,
            statement(
                "SELECT cash,debt,receivable FROM users WHERE id=$1",
                vec![(user).into()],
            ),
        )
        .await
        .map_err(db_error)?;
        let cash: Decimal = value(&u, "cash")?;
        let debt: Decimal = value(&u, "debt")?;
        let receivable: Decimal = value(&u, "receivable")?;
        let mut o = RecordOverview {
            cash,
            debt,
            receivable,
            balance: cash + receivable - debt,
            expenses: vec![],
            incomes: vec![],
            debts: vec![],
        };
        let ids = tx
            .query_all_raw(statement(
                "SELECT id FROM records WHERE owner_id=$1 ORDER BY created_at DESC,id",
                vec![(user).into()],
            ))
            .await
            .map_err(db_error)?;
        for row in ids {
            let r = load_record(&tx, value(&row, "id")?).await?;
            if r.kind == "income" {
                o.incomes.push(r)
            } else {
                o.expenses.push(r)
            }
        }
        let debts=tx.query_all_raw(statement("SELECT d.*,u.username FROM debts d JOIN users u ON u.id=d.debtor_id WHERE owner_id=$1 ORDER BY created_at DESC", vec![(user).into()])).await.map_err(db_error)?;
        for r in debts {
            o.debts.push(Record {
                id: value(&r, "id")?,
                title: format!("Debt with {}", value::<String>(&r, "username")?),
                description: value(&r, "description")?,
                amount: value(&r, "amount")?,
                kind: "debt".into(),
                categories: vec![],
                created_at: value(&r, "created_at")?,
                is_committed: true,
            });
        }
        tx.commit().await.map_err(db_error)?;
        Ok(o)
    }
    async fn commit_record(&self, user: Uuid, c: CommitRecord) -> AppResult<Record> {
        let tx = self.database.begin().await.map_err(db_error)?;
        let row = required(
            &tx,
            statement(
                "SELECT * FROM records WHERE id=$1 AND owner_id=$2 FOR UPDATE",
                vec![(c.record_id).into(), (user).into()],
            ),
        )
        .await
        .map_err(db_error)?;
        if value::<bool>(&row, "is_committed")? {
            return Err(DomainError::Conflict("Record already committed".into()));
        }
        let stored = load_record(&tx, c.record_id).await?;
        let old_primary = stored
            .categories
            .iter()
            .find(|c| c.kind == "primary")
            .map(|c| c.name.clone())
            .unwrap_or_default();
        let old_secondary = stored
            .categories
            .iter()
            .find(|c| c.kind == "secondary")
            .map(|c| c.name.clone())
            .unwrap_or_default();
        let primary = c
            .category
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| old_primary.clone());
        let secondary = c
            .secondary_category
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| {
                if primary != old_primary {
                    primary.clone()
                } else {
                    old_secondary
                }
            });
        self.classifier.validate_categories(&primary, &secondary)?;
        let kind = if primary == "gaji" || primary == "hadiah" {
            "income"
        } else {
            "expense"
        };
        set_categories(&tx, c.record_id, &primary, &secondary).await?;
        let delta = if kind == "income" {
            stored.amount
        } else {
            -stored.amount
        };
        tx.execute_raw(statement(
            "UPDATE users SET cash=cash+$1 WHERE id=$2",
            vec![(delta).into(), (user).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.execute_raw(statement(
            "UPDATE records SET kind=$1,is_committed=TRUE WHERE id=$2",
            vec![(kind).into(), (c.record_id).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.execute_raw(statement("INSERT INTO classifier_feedback(record_id,title,category,secondary_category) VALUES($1,$2,$3,$4)", vec![(c.record_id).into(), (stored.title.as_str()).into(), (primary.as_str()).into(), (secondary.as_str()).into()])).await.map_err(db_error)?;
        tx.execute_raw(statement("INSERT INTO notification_outbox(id,user_id,kind,body) SELECT $1,id,'commit',$2 FROM users WHERE id=$3 AND discord_id IS NOT NULL AND commit_notif", vec![(Uuid::new_v4()).into(), (format!("Tracker: {} — {} ({primary}/{secondary})",stored.title,stored.amount)).into(), (user).into()])).await.map_err(db_error)?;
        let r = load_record(&tx, c.record_id).await?;
        tx.commit().await.map_err(db_error)?;
        Ok(r)
    }
    async fn delete_draft(&self, user: Uuid, id: Uuid) -> AppResult<()> {
        let tx = self.database.begin().await.map_err(db_error)?;
        let r = required(
            &tx,
            statement(
                "SELECT is_committed FROM records WHERE id=$1 AND owner_id=$2 FOR UPDATE",
                vec![(id).into(), (user).into()],
            ),
        )
        .await
        .map_err(db_error)?;
        if value::<bool>(&r, "is_committed")? {
            return Err(DomainError::Conflict(
                "Cannot delete a committed record".into(),
            ));
        }
        tx.execute_raw(statement(
            "DELETE FROM records WHERE id=$1",
            vec![(id).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.commit().await.map_err(db_error)?;
        Ok(())
    }
}
