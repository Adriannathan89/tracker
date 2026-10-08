use super::entities::{session, user};
use super::*;
use crate::security::Passwords;
use chrono::Utc;
use sea_orm::{
    ActiveModelTrait, ActiveValue::Set, ColumnTrait, EntityTrait, QueryFilter, sea_query::Expr,
};
#[async_trait]
impl AuthRepository for PgStore {
    async fn create_user(&self, c: Credentials) -> AppResult<UserSummary> {
        let password = c.password;
        let hash = tokio::task::spawn_blocking(move || Passwords::hash(&password))
            .await
            .map_err(|_| DomainError::Unavailable)??;
        let id = Uuid::new_v4();
        user::ActiveModel {
            id: Set(id),
            username: Set(c.username.clone()),
            password: Set(hash),
            ..Default::default()
        }
        .insert(&self.database)
        .await
        .map_err(db_error)?;
        Ok(UserSummary {
            id,
            username: c.username,
        })
    }
    async fn authenticate(&self, c: Credentials) -> AppResult<UserSummary> {
        let row = user::Entity::find()
            .filter(user::Column::Username.eq(c.username))
            .one(&self.database)
            .await
            .map_err(db_error)?;
        // Perform bcrypt even for unknown users to avoid a cheap username timing oracle.
        let dummy = "$2b$12$abcdefghijklmnopqrstuuE6FhI7pW.j.E.Jg0AYHxODbpoLqAKW2";
        let hash = row
            .as_ref()
            .map(|u| u.password.clone())
            .unwrap_or_else(|| dummy.into());
        let valid = tokio::task::spawn_blocking(move || Passwords::verify(&c.password, &hash))
            .await
            .map_err(|_| DomainError::Unavailable)??;
        let row = row.filter(|_| valid).ok_or(DomainError::Unauthorized)?;
        Ok(UserSummary {
            id: row.id,
            username: row.username,
        })
    }
    async fn save_session(&self, s: Session) -> AppResult<()> {
        session::ActiveModel {
            id: Set(s.id),
            user_id: Set(s.user_id),
            expires_at: Set(s.expires_at),
        }
        .insert(&self.database)
        .await
        .map_err(db_error)?;
        Ok(())
    }
    async fn get_session(&self, id: Uuid) -> AppResult<Session> {
        let row = session::Entity::find_by_id(id)
            .filter(session::Column::ExpiresAt.gt(Utc::now()))
            .one(&self.database)
            .await
            .map_err(db_error)?
            .ok_or(DomainError::Unauthorized)?;
        Ok(Session {
            id: row.id,
            user_id: row.user_id,
            expires_at: row.expires_at,
        })
    }
    async fn revoke_session(&self, id: Uuid) -> AppResult<()> {
        session::Entity::delete_by_id(id)
            .exec(&self.database)
            .await
            .map_err(db_error)?;
        Ok(())
    }
}
#[async_trait]
impl ProfileRepository for PgStore {
    async fn get_profile(&self, id: Uuid) -> AppResult<Profile> {
        let row = user::Entity::find_by_id(id)
            .one(&self.database)
            .await
            .map_err(db_error)?
            .ok_or(DomainError::NotFound)?;
        Ok(Profile {
            id: row.id,
            username: row.username,
            discord: DiscordProfile {
                connected: row.discord_id.is_some(),
                username: row.discord_username.unwrap_or_default(),
                commit_notif_enabled: row.commit_notif,
                weekly_notif_enabled: row.weekly_notif,
            },
        })
    }
    async fn rename(&self, id: Uuid, name: String) -> AppResult<Profile> {
        username(&name)?;
        let result = user::Entity::update_many()
            .col_expr(user::Column::Username, Expr::value(name))
            .filter(user::Column::Id.eq(id))
            .exec(&self.database)
            .await
            .map_err(db_error)?;
        if result.rows_affected == 0 {
            return Err(DomainError::NotFound);
        }
        self.get_profile(id).await
    }
}
