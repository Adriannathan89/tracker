use async_trait::async_trait;
use chrono::{Duration, Utc};
use std::sync::Arc;
pub use tracker_domain::*;
use uuid::Uuid;

pub trait Classifier: Send + Sync {
    fn classify(&self, title: &str) -> AppResult<Classification>;
    fn validate_categories(&self, primary: &str, secondary: &str) -> AppResult<()>;
}
pub trait TokenCodec: Send + Sync {
    fn issue(&self, user_id: Uuid, session_id: Uuid) -> AppResult<TokenPair>;
    fn verify_access(&self, token: &str) -> AppResult<TokenIdentity>;
    fn verify_refresh(&self, token: &str) -> AppResult<TokenIdentity>;
}
#[async_trait]
pub trait AuthRepository: Send + Sync {
    async fn create_user(&self, c: Credentials) -> AppResult<UserSummary>;
    async fn authenticate(&self, c: Credentials) -> AppResult<UserSummary>;
    async fn save_session(&self, s: Session) -> AppResult<()>;
    async fn get_session(&self, id: Uuid) -> AppResult<Session>;
    async fn revoke_session(&self, id: Uuid) -> AppResult<()>;
}
#[async_trait]
pub trait ProfileRepository: Send + Sync {
    async fn get_profile(&self, id: Uuid) -> AppResult<Profile>;
    async fn rename(&self, id: Uuid, name: String) -> AppResult<Profile>;
}
#[async_trait]
pub trait RecordRepository: Send + Sync {
    async fn create_record(
        &self,
        id: Uuid,
        c: CreateRecord,
        p: Classification,
    ) -> AppResult<Record>;
    async fn list_records(&self, id: Uuid) -> AppResult<RecordOverview>;
    async fn commit_record(&self, id: Uuid, c: CommitRecord) -> AppResult<Record>;
    async fn delete_draft(&self, id: Uuid, record: Uuid) -> AppResult<()>;
}
#[async_trait]
pub trait FriendRepository: Send + Sync {
    async fn search_friends(&self, id: Uuid, name: String) -> AppResult<Vec<Friend>>;
    async fn list_friends(&self, id: Uuid) -> AppResult<Vec<Friend>>;
    async fn requests(&self, id: Uuid) -> AppResult<Vec<FriendRequest>>;
    async fn send_request(&self, id: Uuid, friend: Uuid) -> AppResult<()>;
    async fn respond(&self, id: Uuid, request: Uuid, action: FriendAction) -> AppResult<()>;
}
#[async_trait]
pub trait DebtRepository: Send + Sync {
    async fn create_debt(&self, id: Uuid, c: CreateDebt) -> AppResult<Debt>;
    async fn finish_debt(&self, id: Uuid, debt: Uuid) -> AppResult<Debt>;
    async fn list_debts(&self, id: Uuid, owed: bool) -> AppResult<Vec<Debt>>;
}
#[async_trait]
pub trait DiscordRepository: Send + Sync {
    async fn generate_code(&self, id: Uuid) -> AppResult<DiscordVerification>;
    async fn verify_code(&self, code: String, discord_id: String, name: String) -> AppResult<()>;
    async fn discord_status(&self, id: Uuid) -> AppResult<DiscordStatus>;
    async fn disconnect(&self, id: Uuid) -> AppResult<()>;
    async fn set_notification(
        &self,
        id: Uuid,
        kind: NotificationKind,
        enabled: bool,
    ) -> AppResult<()>;
}
#[async_trait]
pub trait Health: Send + Sync {
    async fn ready(&self) -> AppResult<()>;
}
pub trait Repository:
    AuthRepository
    + ProfileRepository
    + RecordRepository
    + FriendRepository
    + DebtRepository
    + DiscordRepository
    + Health
{
}
impl<
    T: AuthRepository
        + ProfileRepository
        + RecordRepository
        + FriendRepository
        + DebtRepository
        + DiscordRepository
        + Health,
> Repository for T
{
}

pub struct Services {
    pub repository: Arc<dyn Repository>,
    pub classifier: Arc<dyn Classifier>,
    pub tokens: Arc<dyn TokenCodec>,
}
impl Services {
    pub fn new(
        repository: Arc<dyn Repository>,
        classifier: Arc<dyn Classifier>,
        tokens: Arc<dyn TokenCodec>,
    ) -> Self {
        Self {
            repository,
            classifier,
            tokens,
        }
    }
    pub async fn register(&self, c: Credentials) -> AppResult<UserSummary> {
        username(&c.username)?;
        if !(8..=72).contains(&c.password.len()) || c.password.contains('\0') {
            return Err(DomainError::Validation(
                "Password must contain 8–72 bytes".into(),
            ));
        }
        self.repository.create_user(c).await
    }
    pub async fn login(&self, c: Credentials) -> AppResult<(UserSummary, TokenPair)> {
        if c.username.len() > 200 || c.password.len() > 72 {
            return Err(DomainError::Unauthorized);
        }
        let user = self.repository.authenticate(c).await?;
        let id = Uuid::new_v4();
        let tokens = self.tokens.issue(user.id, id)?;
        self.repository
            .save_session(Session {
                id,
                user_id: user.id,
                expires_at: Utc::now() + Duration::days(30),
            })
            .await?;
        Ok((user, tokens))
    }
    pub async fn validate(&self, identity: TokenIdentity) -> AppResult<Uuid> {
        let s = self.repository.get_session(identity.session_id).await?;
        if s.user_id != identity.user_id || s.expires_at <= Utc::now() {
            return Err(DomainError::Unauthorized);
        }
        Ok(s.user_id)
    }
    pub async fn refresh(&self, token: &str) -> AppResult<(Uuid, TokenPair)> {
        let i = self.tokens.verify_refresh(token)?;
        let id = self.validate(i.clone()).await?;
        Ok((id, self.tokens.issue(id, i.session_id)?))
    }
    pub async fn logout(&self, refresh: &str) -> AppResult<()> {
        if let Ok(i) = self.tokens.verify_refresh(refresh) {
            self.repository.revoke_session(i.session_id).await?;
        }
        Ok(())
    }
    pub async fn create_record(&self, id: Uuid, c: CreateRecord) -> AppResult<Record> {
        amount(c.amount)?;
        if c.title.trim().is_empty() || c.title.chars().count() > 200 || c.description.len() > 4000
        {
            return Err(DomainError::Validation(
                "Invalid title or description".into(),
            ));
        }
        let p = self.classifier.classify(&c.title)?;
        self.repository.create_record(id, c, p).await
    }
    pub async fn create_debt(&self, id: Uuid, c: CreateDebt) -> AppResult<Debt> {
        amount(c.amount)?;
        if id == c.debtor_id || c.description.trim().is_empty() || c.description.len() > 4000 {
            return Err(DomainError::Validation(
                "Invalid debtor or description".into(),
            ));
        }
        self.repository.create_debt(id, c).await
    }
    pub async fn rename(&self, id: Uuid, name: String) -> AppResult<Profile> {
        username(&name)?;
        self.repository.rename(id, name).await
    }
    pub async fn list_records(&self, id: Uuid) -> AppResult<RecordOverview> {
        self.repository.list_records(id).await
    }
    pub async fn commit_record(&self, id: Uuid, c: CommitRecord) -> AppResult<Record> {
        self.repository.commit_record(id, c).await
    }
    pub async fn delete_draft(&self, id: Uuid, record: Uuid) -> AppResult<()> {
        self.repository.delete_draft(id, record).await
    }
    pub async fn search_friends(&self, id: Uuid, name: String) -> AppResult<Vec<Friend>> {
        self.repository.search_friends(id, name).await
    }
    pub async fn list_friends(&self, id: Uuid) -> AppResult<Vec<Friend>> {
        self.repository.list_friends(id).await
    }
    pub async fn requests(&self, id: Uuid) -> AppResult<Vec<FriendRequest>> {
        self.repository.requests(id).await
    }
    pub async fn send_request(&self, id: Uuid, friend: Uuid) -> AppResult<()> {
        self.repository.send_request(id, friend).await
    }
    pub async fn respond(&self, id: Uuid, request: Uuid, action: FriendAction) -> AppResult<()> {
        self.repository.respond(id, request, action).await
    }
    pub async fn finish_debt(&self, id: Uuid, debt: Uuid) -> AppResult<Debt> {
        self.repository.finish_debt(id, debt).await
    }
    pub async fn list_debts(&self, id: Uuid, owed: bool) -> AppResult<Vec<Debt>> {
        self.repository.list_debts(id, owed).await
    }
    pub async fn generate_code(&self, id: Uuid) -> AppResult<DiscordVerification> {
        self.repository.generate_code(id).await
    }
    pub async fn verify_code(
        &self,
        code: String,
        discord_id: String,
        name: String,
    ) -> AppResult<()> {
        self.repository.verify_code(code, discord_id, name).await
    }
    pub async fn discord_status(&self, id: Uuid) -> AppResult<DiscordStatus> {
        self.repository.discord_status(id).await
    }
    pub async fn disconnect(&self, id: Uuid) -> AppResult<()> {
        self.repository.disconnect(id).await
    }
    pub async fn set_notification(
        &self,
        id: Uuid,
        kind: NotificationKind,
        enabled: bool,
    ) -> AppResult<()> {
        self.repository.set_notification(id, kind, enabled).await
    }
    pub async fn get_profile(&self, id: Uuid) -> AppResult<Profile> {
        self.repository.get_profile(id).await
    }
}
