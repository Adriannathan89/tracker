use super::*;
use crate::postgres::{db_error, required, statement, value};
use rust_decimal::Decimal;
use sea_orm::{ConnectionTrait, TransactionTrait};
use uuid::Uuid;

pub async fn enqueue_weekly_report(
    store: &PgStore,
    user: Uuid,
    week_key: &str,
    body: &str,
) -> AppResult<bool> {
    let tx = store.database().begin().await.map_err(db_error)?;
    let row = tx
        .execute_raw(statement(
            "INSERT INTO report_deliveries(user_id,week_key) VALUES($1,$2) ON CONFLICT DO NOTHING",
            vec![(user).into(), (week_key).into()],
        ))
        .await
        .map_err(db_error)?;
    if row.rows_affected() == 0 {
        return Ok(false);
    }
    tx.execute_raw(statement(
        "INSERT INTO notification_outbox(id,user_id,kind,body) VALUES($1,$2,'weekly',$3)",
        vec![(Uuid::new_v4()).into(), (user).into(), (body).into()],
    ))
    .await
    .map_err(db_error)?;
    tx.commit().await.map_err(db_error)?;
    Ok(true)
}
pub(super) async fn run_once(
    store: &PgStore,
    config: &DiscordConfig,
    client: &reqwest::Client,
) -> AppResult<()> {
    let now = Utc::now();
    store
        .database()
        .execute_raw(statement(
            "DELETE FROM discord_verifications WHERE expires_at<NOW()-INTERVAL '1 hour'",
            vec![],
        ))
        .await
        .map_err(db_error)?;
    store
        .database()
        .execute_raw(statement(
            "DELETE FROM sessions WHERE expires_at<NOW()",
            vec![],
        ))
        .await
        .map_err(db_error)?;
    if is_weekly_window(now) {
        let users=store.database().query_all_raw(statement("SELECT id,username,cash,debt,receivable FROM users WHERE discord_id IS NOT NULL AND weekly_notif", vec![])).await.map_err(db_error)?;
        let week_key = (now + chrono::Duration::hours(7))
            .format("%Y-%m-%d")
            .to_string();
        for u in users {
            let user: Uuid = value(&u, "id")?;
            let (start, end) = report_window(now);
            let r=required(store.database(), statement("SELECT COALESCE(SUM(amount) FILTER(WHERE kind='income'),0) AS income,COALESCE(SUM(amount) FILTER(WHERE kind='expense'),0) AS expense FROM records WHERE owner_id=$1 AND is_committed AND created_at >= $2 AND created_at < $3", vec![(user).into(), (start).into(), (end).into()])).await.map_err(db_error)?;
            let top=store.database().query_all_raw(statement("SELECT c.name,SUM(r.amount) AS total FROM records r JOIN record_categories rc ON rc.record_id=r.id JOIN categories c ON c.id=rc.category_id WHERE r.owner_id=$1 AND r.is_committed AND r.kind='expense' AND c.kind='primary' AND r.created_at >= $2 AND r.created_at < $3 GROUP BY c.name ORDER BY total DESC,c.name LIMIT 3", vec![(user).into(), (start).into(), (end).into()])).await.map_err(db_error)?;
            let categories = top
                .iter()
                .map(|row| {
                    Ok((
                        value::<String>(row, "name")?,
                        value::<Decimal>(row, "total")?,
                    ))
                })
                .collect::<AppResult<Vec<_>>>()?;
            let report = WeeklyReport {
                start,
                end,
                income: value(&r, "income")?,
                expense: value(&r, "expense")?,
                top_categories: categories,
            };
            let body = format_weekly_report(&report);
            enqueue_weekly_report(store, user, &week_key, &body).await?;
        }
    }
    // Lease one pending message; retries are bounded and may redeliver after a crash.
    for _ in 0..10 {
        let row=store.database().query_one_raw(statement("WITH candidate AS (SELECT id FROM notification_outbox WHERE delivered_at IS NULL AND attempts<5 AND available_at<=NOW() AND (lease_until IS NULL OR lease_until<NOW()) ORDER BY available_at,id FOR UPDATE SKIP LOCKED LIMIT 1), claimed AS (UPDATE notification_outbox n SET lease_until=NOW()+INTERVAL '60 seconds',attempts=n.attempts+1 FROM candidate c WHERE n.id=c.id RETURNING n.*) SELECT c.*,u.discord_id,u.commit_notif,u.weekly_notif FROM claimed c JOIN users u ON u.id=c.user_id", vec![])).await.map_err(db_error)?;
        let Some(r) = row else { break };
        let id: Uuid = value(&r, "id")?;
        let destination: Option<String> = value(&r, "discord_id")?;
        let kind: String = value(&r, "kind")?;
        let enabled: bool = value(
            &r,
            if kind == "commit" {
                "commit_notif"
            } else {
                "weekly_notif"
            },
        )?;
        let delivered = if let Some(destination) = destination.filter(|_| enabled) {
            send(client, config, &destination, &value::<String>(&r, "body")?)
                .await
                .is_ok()
        } else {
            true
        };
        if delivered {
            store.database().execute_raw(statement("UPDATE notification_outbox SET delivered_at=NOW(),lease_until=NULL WHERE id=$1", vec![(id).into()]))
            .await
            .map_err(db_error)?;
        } else {
            store.database().execute_raw(statement("UPDATE notification_outbox SET available_at=NOW()+INTERVAL '60 seconds'*attempts,lease_until=NULL WHERE id=$1", vec![(id).into()])).await.map_err(db_error)?;
        }
    }
    Ok(())
}
async fn send(
    client: &reqwest::Client,
    cfg: &DiscordConfig,
    recipient: &str,
    body: &str,
) -> AppResult<()> {
    let response = client
        .post("https://discord.com/api/v10/users/@me/channels")
        .header("Authorization", format!("Bot {}", cfg.token))
        .json(&serde_json::json!({"recipient_id":recipient}))
        .send()
        .await
        .map_err(|_| DomainError::Unavailable)?;
    if !response.status().is_success() {
        return Err(DomainError::Unavailable);
    }
    let channel: serde_json::Value = response
        .json()
        .await
        .map_err(|_| DomainError::Unavailable)?;
    let id = channel["id"].as_str().ok_or(DomainError::Unavailable)?;
    let response=client.post(format!("https://discord.com/api/v10/channels/{id}/messages")).header("Authorization",format!("Bot {}",cfg.token)).json(&serde_json::json!({"content":body.chars().take(1900).collect::<String>(),"allowed_mentions":{"parse":[]}})).send().await.map_err(|_|DomainError::Unavailable)?;
    if response.status().is_success() {
        Ok(())
    } else {
        Err(DomainError::Unavailable)
    }
}
