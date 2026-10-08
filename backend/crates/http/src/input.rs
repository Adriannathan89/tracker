//! Delivery DTOs validated by Furnace before invoking application use cases.
use furnace_rs::prelude::*;
use rust_decimal::Decimal;
use serde::Deserialize;
use tracker_application::{self as app, AppResult};

fn issue(code: &str, message: &str) -> ValidationResult {
    Err(ValidationErrors::from_issue(ValidationIssue::custom(
        code, message,
    )))
}
fn clean_username(value: &str) -> ValidationResult {
    if value.trim() != value || value.chars().any(char::is_control) {
        issue(
            "invalid_username",
            "username must not contain surrounding whitespace or control characters",
        )
    } else {
        Ok(())
    }
}
fn register_password(value: &str) -> ValidationResult {
    if !(8..=72).contains(&value.len()) || value.contains('\0') {
        issue(
            "invalid_password",
            "password must contain 8–72 bytes and no null character",
        )
    } else {
        Ok(())
    }
}
fn login_password(value: &str) -> ValidationResult {
    if value.len() > 72 || value.contains('\0') {
        issue(
            "invalid_password",
            "password exceeds its byte limit or contains a null character",
        )
    } else {
        Ok(())
    }
}
fn nonblank(value: &str) -> ValidationResult {
    if value.trim().is_empty() {
        issue("nonempty", "must contain non-whitespace text")
    } else {
        Ok(())
    }
}
fn description(value: &str) -> ValidationResult {
    if value.len() > 4000 {
        issue("too_long", "description must contain at most 4000 bytes")
    } else {
        Ok(())
    }
}
fn debt_description(value: &str) -> ValidationResult {
    nonblank(value)?;
    description(value)
}
fn money(value: &Decimal) -> ValidationResult {
    let result: AppResult<Decimal> = app::amount(*value);
    if result.is_err() {
        issue(
            "invalid_amount",
            "amount must be positive, below 10^18, with at most two decimal places",
        )
    } else {
        Ok(())
    }
}

#[derive(Deserialize, Input)]
pub struct RegisterInput {
    #[validate(length(min = 3, max = 50), custom = clean_username)]
    pub username: String,
    #[validate(custom = register_password)]
    pub password: String,
}
impl From<RegisterInput> for app::Credentials {
    fn from(input: RegisterInput) -> Self {
        Self {
            username: input.username,
            password: input.password,
        }
    }
}
#[derive(Deserialize, Input)]
pub struct LoginInput {
    #[validate(nonempty, length(max = 200))]
    pub username: String,
    #[validate(nonempty, custom = login_password)]
    pub password: String,
}
impl From<LoginInput> for app::Credentials {
    fn from(input: LoginInput) -> Self {
        Self {
            username: input.username,
            password: input.password,
        }
    }
}
#[derive(Deserialize, Input)]
pub struct CreateRecordInput {
    #[validate(nonempty, length(max = 200), custom = nonblank)]
    pub title: String,
    #[serde(default)]
    #[validate(custom = description)]
    pub description: String,
    #[serde(with = "rust_decimal::serde::float")]
    #[validate(custom = money)]
    pub amount: Decimal,
    pub date: chrono::NaiveDate,
}
impl From<CreateRecordInput> for app::CreateRecord {
    fn from(input: CreateRecordInput) -> Self {
        Self {
            title: input.title,
            description: input.description,
            amount: input.amount,
            date: input.date,
        }
    }
}
#[derive(Deserialize, Input)]
#[serde(rename_all = "camelCase")]
pub struct CommitRecordInput {
    pub record_id: uuid::Uuid,
    #[validate(length(max = 100))]
    pub category: Option<String>,
    #[validate(length(max = 100))]
    pub secondary_category: Option<String>,
}
impl From<CommitRecordInput> for app::CommitRecord {
    fn from(input: CommitRecordInput) -> Self {
        Self {
            record_id: input.record_id,
            category: input.category,
            secondary_category: input.secondary_category,
        }
    }
}
#[derive(Deserialize, Input)]
#[serde(rename_all = "camelCase")]
pub struct CreateDebtInput {
    #[serde(with = "rust_decimal::serde::float")]
    #[validate(custom = money)]
    pub amount: Decimal,
    #[validate(nonempty, custom = debt_description)]
    pub description: String,
    pub debtor_id: uuid::Uuid,
}
impl From<CreateDebtInput> for app::CreateDebt {
    fn from(input: CreateDebtInput) -> Self {
        Self {
            amount: input.amount,
            description: input.description,
            debtor_id: input.debtor_id,
        }
    }
}
