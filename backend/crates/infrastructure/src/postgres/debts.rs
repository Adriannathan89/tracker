use super::*;
use rust_decimal::Decimal;
// Only constant SQL fragments are formatted; user values always use bind parameters.
const DEBTS: &str = "SELECT d.*,o.username AS owner_username,b.username AS debtor_username FROM debts d JOIN users o ON o.id=d.owner_id JOIN users b ON b.id=d.debtor_id";
fn decode(r: &QueryResult) -> AppResult<Debt> {
    let owner_id = value(r, "owner_id")?;
    let debtor_id = value(r, "debtor_id")?;
    Ok(Debt {
        id: value(r, "id")?,
        owner_id,
        debtor_id,
        owner: UserSummary {
            id: owner_id,
            username: value(r, "owner_username")?,
        },
        debtor: UserSummary {
            id: debtor_id,
            username: value(r, "debtor_username")?,
        },
        amount: value(r, "amount")?,
        description: value(r, "description")?,
        status: value(r, "status")?,
        created_at: value(r, "created_at")?,
    })
}
async fn ledger(
    conn: &impl ConnectionTrait,
    user: Uuid,
    title: String,
    description: &str,
    amount: Decimal,
    kind: &str,
) -> AppResult<()> {
    conn.execute_raw(statement("INSERT INTO records(id,owner_id,title,description,amount,kind,created_at,is_committed) VALUES($1,$2,$3,$4,$5,$6,NOW(),TRUE)", vec![(Uuid::new_v4()).into(), (user).into(), (title).into(), (description).into(), (amount).into(), (kind).into()])).await.map_err(db_error)?;
    Ok(())
}
#[async_trait]
impl DebtRepository for PgStore {
    async fn create_debt(&self, user: Uuid, c: CreateDebt) -> AppResult<Debt> {
        amount(c.amount)?;
        if user == c.debtor_id {
            return Err(DomainError::Validation("Cannot create a self debt".into()));
        }
        let id = Uuid::new_v4();
        let tx = self.database.begin().await.map_err(db_error)?;
        lock_users(&tx, user, c.debtor_id).await?;
        tx.execute_raw(statement(
            "UPDATE users SET receivable=receivable+$1,cash=cash-$1 WHERE id=$2",
            vec![(c.amount).into(), (user).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.execute_raw(statement(
            "UPDATE users SET debt=debt+$1 WHERE id=$2",
            vec![(c.amount).into(), (c.debtor_id).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.execute_raw(statement(
            "INSERT INTO debts(id,owner_id,debtor_id,amount,description) VALUES($1,$2,$3,$4,$5)",
            vec![
                (id).into(),
                (user).into(),
                (c.debtor_id).into(),
                (c.amount).into(),
                (c.description.as_str()).into(),
            ],
        ))
        .await
        .map_err(db_error)?;
        let r = required(
            &tx,
            statement(format!("{DEBTS} WHERE d.id=$1"), vec![(id).into()]),
        )
        .await
        .map_err(db_error)?;
        let d = decode(&r)?;
        ledger(
            &tx,
            user,
            format!("Hutang ke {}", d.debtor.username),
            &c.description,
            c.amount,
            "expense",
        )
        .await?;
        tx.commit().await.map_err(db_error)?;
        Ok(d)
    }
    async fn finish_debt(&self, user: Uuid, id: Uuid) -> AppResult<Debt> {
        let tx = self.database.begin().await.map_err(db_error)?;
        let r = required(
            &tx,
            statement(
                "SELECT * FROM debts WHERE id=$1 FOR UPDATE",
                vec![(id).into()],
            ),
        )
        .await
        .map_err(db_error)?;
        let owner: Uuid = value(&r, "owner_id")?;
        let debtor: Uuid = value(&r, "debtor_id")?;
        if user != debtor {
            return Err(DomainError::Forbidden);
        }
        if value::<String>(&r, "status")? != "pending" {
            return Err(DomainError::Conflict("Debt already completed".into()));
        }
        lock_users(&tx, owner, debtor).await?;
        let amount: Decimal = value(&r, "amount")?;
        tx.execute_raw(statement(
            "UPDATE users SET receivable=receivable-$1,cash=cash+$1 WHERE id=$2",
            vec![(amount).into(), (owner).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.execute_raw(statement(
            "UPDATE users SET debt=debt-$1,cash=cash-$1 WHERE id=$2",
            vec![(amount).into(), (debtor).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.execute_raw(statement(
            "UPDATE debts SET status='completed' WHERE id=$1",
            vec![(id).into()],
        ))
        .await
        .map_err(db_error)?;
        let r = required(
            &tx,
            statement(format!("{DEBTS} WHERE d.id=$1"), vec![(id).into()]),
        )
        .await
        .map_err(db_error)?;
        let d = decode(&r)?;
        ledger(
            &tx,
            owner,
            format!("Piutang lunas dari {}", d.debtor.username),
            &d.description,
            amount,
            "income",
        )
        .await?;
        ledger(
            &tx,
            debtor,
            format!("Bayar hutang ke {}", d.owner.username),
            &d.description,
            amount,
            "expense",
        )
        .await?;
        tx.commit().await.map_err(db_error)?;
        Ok(d)
    }
    async fn list_debts(&self, user: Uuid, owed: bool) -> AppResult<Vec<Debt>> {
        let clause = if owed {
            "d.debtor_id=$1 AND d.status='pending'"
        } else {
            "d.owner_id=$1"
        };
        self.database
            .query_all_raw(statement(
                format!("{DEBTS} WHERE {clause} ORDER BY d.created_at DESC,d.id"),
                vec![(user).into()],
            ))
            .await
            .map_err(db_error)?
            .iter()
            .map(decode)
            .collect()
    }
}
