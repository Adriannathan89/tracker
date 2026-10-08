use super::*;
use chrono::{Duration, Utc};
use rand::Rng;
#[async_trait]
impl DiscordRepository for PgStore {
    async fn generate_code(&self, user: Uuid) -> AppResult<DiscordVerification> {
        // Regeneration and verification serialize on the user row.
        for _ in 0..10 {
            let tx = self.database.begin().await.map_err(db_error)?;
            required(
                &tx,
                statement(
                    "SELECT id FROM users WHERE id=$1 FOR UPDATE",
                    vec![(user).into()],
                ),
            )
            .await
            .map_err(db_error)?;
            let code = format!("{:06}", rand::thread_rng().gen_range(0..1_000_000));
            let expires_at = Utc::now() + Duration::minutes(10);
            let result=tx.execute_raw(statement("INSERT INTO discord_verifications(user_id,code,expires_at) VALUES($1,$2,$3) ON CONFLICT(user_id) DO UPDATE SET code=$2,expires_at=$3", vec![(user).into(), (code.as_str()).into(), (expires_at).into()])).await;
            match result {
                Ok(_) => {
                    tx.commit().await.map_err(db_error)?;
                    return Ok(DiscordVerification { code, expires_at });
                }
                Err(ref e) if matches!(e.sql_err(), Some(SqlErr::UniqueConstraintViolation(_))) => {
                    continue;
                }
                Err(e) => return Err(db_error(e)),
            }
        }
        Err(DomainError::Unavailable)
    }
    async fn verify_code(&self, code: String, discord_id: String, name: String) -> AppResult<()> {
        if code.len() != 6 || !code.bytes().all(|b| b.is_ascii_digit()) {
            return Err(DomainError::Validation("Invalid code".into()));
        }
        let tx = self.database.begin().await.map_err(db_error)?;
        let row = tx
            .query_one_raw(statement(
                "SELECT user_id FROM discord_verifications WHERE code=$1 AND expires_at>NOW()",
                vec![(code.as_str()).into()],
            ))
            .await
            .map_err(db_error)?
            .ok_or_else(|| DomainError::Validation("Invalid or expired code".into()))?;
        let user: Uuid = value(&row, "user_id")?;
        required(
            &tx,
            statement(
                "SELECT id FROM users WHERE id=$1 FOR UPDATE",
                vec![(user).into()],
            ),
        )
        .await
        .map_err(db_error)?;
        let result = tx.execute_raw(statement("DELETE FROM discord_verifications WHERE user_id=$1 AND code=$2 AND expires_at>NOW()", vec![(user).into(), (code).into()]))
        .await
        .map_err(db_error)?;
        if result.rows_affected() != 1 {
            return Err(DomainError::Validation("Invalid or expired code".into()));
        }
        tx.execute_raw(statement(
            "UPDATE users SET discord_id=$1,discord_username=$2 WHERE id=$3",
            vec![(discord_id).into(), (name).into(), (user).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.commit().await.map_err(db_error)?;
        Ok(())
    }
    async fn discord_status(&self, user: Uuid) -> AppResult<DiscordStatus> {
        let p = self.get_profile(user).await?;
        Ok(DiscordStatus {
            verified: p.discord.connected,
            discord_username: p.discord.username,
        })
    }
    async fn disconnect(&self, user: Uuid) -> AppResult<()> {
        let tx = self.database.begin().await.map_err(db_error)?;
        tx.execute_raw(statement(
            "UPDATE users SET discord_id=NULL,discord_username=NULL WHERE id=$1",
            vec![(user).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.execute_raw(statement(
            "DELETE FROM discord_verifications WHERE user_id=$1",
            vec![(user).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.execute_raw(statement(
            "DELETE FROM notification_outbox WHERE user_id=$1 AND delivered_at IS NULL",
            vec![(user).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.commit().await.map_err(db_error)?;
        Ok(())
    }
    async fn set_notification(
        &self,
        user: Uuid,
        kind: NotificationKind,
        enabled: bool,
    ) -> AppResult<()> {
        self.database
            .execute_raw(statement(
                match kind {
                    NotificationKind::Commit => "UPDATE users SET commit_notif=$1 WHERE id=$2",
                    NotificationKind::Weekly => "UPDATE users SET weekly_notif=$1 WHERE id=$2",
                },
                vec![(enabled).into(), (user).into()],
            ))
            .await
            .map_err(db_error)?;
        Ok(())
    }
}
