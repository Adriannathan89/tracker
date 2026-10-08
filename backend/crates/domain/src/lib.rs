use chrono::{DateTime, NaiveDate, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

pub type AppResult<T> = Result<T, DomainError>;
#[derive(Debug, thiserror::Error)]
pub enum DomainError {
    #[error("{0}")]
    Validation(String),
    #[error("Unauthorized")]
    Unauthorized,
    #[error("Forbidden")]
    Forbidden,
    #[error("Not found")]
    NotFound,
    #[error("{0}")]
    Conflict(String),
    #[error("Service unavailable")]
    Unavailable,
}
pub fn amount(value: Decimal) -> AppResult<Decimal> {
    if value <= Decimal::ZERO
        || value.scale() > 2
        || value >= Decimal::from(1_000_000_000_000_000_000i64)
    {
        return Err(DomainError::Validation(
            "Amount must be positive with at most two decimal places".into(),
        ));
    }
    Ok(value)
}
pub fn username(value: &str) -> AppResult<()> {
    if !(3..=50).contains(&value.chars().count())
        || value.trim() != value
        || value.chars().any(char::is_control)
    {
        return Err(DomainError::Validation(
            "Username must contain 3–50 characters".into(),
        ));
    }
    Ok(())
}
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UserSummary {
    pub id: Uuid,
    pub username: String,
}
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Category {
    pub id: Uuid,
    pub name: String,
    #[serde(rename = "type")]
    pub kind: String,
}
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Record {
    pub id: Uuid,
    pub title: String,
    pub description: String,
    #[serde(with = "rust_decimal::serde::float")]
    pub amount: Decimal,
    #[serde(rename = "type")]
    pub kind: String,
    pub categories: Vec<Category>,
    pub created_at: DateTime<Utc>,
    pub is_committed: bool,
}
#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Debt {
    pub id: Uuid,
    pub owner_id: Uuid,
    pub debtor_id: Uuid,
    pub owner: UserSummary,
    pub debtor: UserSummary,
    #[serde(with = "rust_decimal::serde::float")]
    pub amount: Decimal,
    pub description: String,
    pub status: String,
    pub created_at: DateTime<Utc>,
}
#[derive(Clone, Debug, Serialize)]
pub struct Friend {
    pub id: Uuid,
    pub username: String,
    pub status: String,
}
#[derive(Clone, Debug, Serialize)]
pub struct FriendRequest {
    pub id: Uuid,
    pub sender: UserSummary,
    pub receiver: UserSummary,
}
#[derive(Clone, Debug, Serialize)]
pub struct RecordOverview {
    pub expenses: Vec<Record>,
    pub incomes: Vec<Record>,
    pub debts: Vec<Record>,
    #[serde(with = "rust_decimal::serde::float")]
    pub cash: Decimal,
    #[serde(with = "rust_decimal::serde::float")]
    pub debt: Decimal,
    #[serde(with = "rust_decimal::serde::float")]
    pub receivable: Decimal,
    #[serde(with = "rust_decimal::serde::float")]
    pub balance: Decimal,
}
#[derive(Clone, Debug, Serialize)]
pub struct Profile {
    pub id: Uuid,
    pub username: String,
    pub discord: DiscordProfile,
}
#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DiscordProfile {
    pub connected: bool,
    pub username: String,
    pub commit_notif_enabled: bool,
    pub weekly_notif_enabled: bool,
}
#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DiscordStatus {
    pub verified: bool,
    pub discord_username: String,
}
#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DiscordVerification {
    pub code: String,
    pub expires_at: DateTime<Utc>,
}
#[derive(Clone, Debug)]
pub struct Session {
    pub id: Uuid,
    pub user_id: Uuid,
    pub expires_at: DateTime<Utc>,
}
#[derive(Clone, Debug)]
pub struct TokenPair {
    pub access: String,
    pub refresh: String,
}
#[derive(Clone, Debug)]
pub struct TokenIdentity {
    pub user_id: Uuid,
    pub session_id: Uuid,
    pub expires_at: i64,
}
#[derive(Clone, Debug)]
pub struct Classification {
    pub category: String,
    pub secondary_category: String,
    pub kind: String,
    pub primary_probabilities: Vec<f64>,
    pub secondary_probabilities: Vec<f64>,
}
#[derive(Clone, Debug, Deserialize)]
pub struct Credentials {
    pub username: String,
    pub password: String,
}
#[derive(Clone, Debug, Deserialize)]
pub struct CreateRecord {
    pub title: String,
    #[serde(default)]
    pub description: String,
    #[serde(with = "rust_decimal::serde::float")]
    pub amount: Decimal,
    pub date: NaiveDate,
}
#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CommitRecord {
    pub record_id: Uuid,
    pub category: Option<String>,
    pub secondary_category: Option<String>,
}
#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateDebt {
    #[serde(with = "rust_decimal::serde::float")]
    pub amount: Decimal,
    pub description: String,
    pub debtor_id: Uuid,
}
#[derive(Clone, Copy, Debug, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum FriendAction {
    Accept,
    Reject,
}
#[derive(Clone, Copy, Debug, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum NotificationKind {
    Commit,
    Weekly,
}
