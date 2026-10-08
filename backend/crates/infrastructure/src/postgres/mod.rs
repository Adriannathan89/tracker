use async_trait::async_trait;
use sea_orm::{
    ConnectionTrait, Database, DatabaseConnection, DbBackend, DbErr, QueryResult, RuntimeErr,
    SqlErr, Statement, TransactionTrait, TryGetable, Value,
};
use std::sync::Arc;
use tracker_application::*;
use uuid::Uuid;
pub(crate) mod auth;
pub(crate) mod debts;
pub(crate) mod discord;
mod entities;
pub(crate) mod friends;
pub(crate) mod records;

#[furnace_rs::storage]
pub struct PgStore {
    pub(crate) database: DatabaseConnection,
    pub(crate) classifier: Arc<dyn Classifier>,
}
impl PgStore {
    pub async fn connect(url: &str, classifier: Arc<dyn Classifier>) -> AppResult<Self> {
        let database = Database::connect(url).await.map_err(db_error)?;
        Self::migrate(&database).await?;
        <Self as furnace_rs::Injector>::inject((database, classifier))
            .await
            .map_err(|_| DomainError::Unavailable)
    }
    /// Apply the embedded schema once, atomically, with serialized startup and checksum verification.
    pub async fn migrate(database: &DatabaseConnection) -> AppResult<()> {
        use sha2::{Digest, Sha256};
        let schema = include_str!("../../../../migrations/0001_tracker.sql");
        let checksum = format!("{:x}", Sha256::digest(schema.as_bytes()));
        let tx = database.begin().await.map_err(db_error)?;
        // A transaction-scoped lock serializes parallel backend startup, including ledger creation.
        tx.query_one_raw(statement("SELECT pg_advisory_xact_lock(7261636)", vec![]))
            .await
            .map_err(db_error)?;
        tx.execute_unprepared("CREATE TABLE IF NOT EXISTS tracker_migrations (version BIGINT PRIMARY KEY, checksum TEXT NOT NULL, applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW())")
            .await.map_err(db_error)?;
        let existing = tx
            .query_one_raw(statement(
                "SELECT checksum FROM tracker_migrations WHERE version=$1",
                vec![1_i64.into()],
            ))
            .await
            .map_err(db_error)?;
        if let Some(row) = existing {
            if value::<String>(&row, "checksum")? != checksum {
                return Err(DomainError::Validation(
                    "Migration checksum mismatch".into(),
                ));
            }
        } else {
            tx.execute_unprepared(schema).await.map_err(db_error)?;
            tx.execute_raw(statement(
                "INSERT INTO tracker_migrations(version,checksum) VALUES($1,$2)",
                vec![1_i64.into(), checksum.into()],
            ))
            .await
            .map_err(db_error)?;
        }
        tx.commit().await.map_err(db_error)
    }
    pub fn database(&self) -> &DatabaseConnection {
        &self.database
    }
}
pub(crate) fn statement(sql: impl Into<String>, values: Vec<Value>) -> Statement {
    Statement::from_sql_and_values(DbBackend::Postgres, sql, values)
}
pub(crate) async fn required(
    connection: &impl ConnectionTrait,
    statement: Statement,
) -> Result<QueryResult, DbErr> {
    connection
        .query_one_raw(statement)
        .await?
        .ok_or_else(|| DbErr::RecordNotFound("Record not found".into()))
}
pub(crate) fn db_error(e: DbErr) -> DomainError {
    if matches!(e, DbErr::RecordNotFound(_)) {
        return DomainError::NotFound;
    }
    match e.sql_err() {
        Some(SqlErr::UniqueConstraintViolation(_)) => {
            return DomainError::Conflict("Already exists".into());
        }
        Some(SqlErr::ForeignKeyConstraintViolation(_)) => return DomainError::NotFound,
        _ => {}
    }
    if let DbErr::Exec(RuntimeErr::SqlxError(ref err))
    | DbErr::Query(RuntimeErr::SqlxError(ref err)) = e
        && err
            .as_database_error()
            .and_then(|error| error.code())
            .as_deref()
            == Some("23514")
    {
        return DomainError::Validation("Invalid values".into());
    }
    eprintln!("database operation failed: {e}");
    DomainError::Unavailable
}
pub(crate) fn value<T: TryGetable>(row: &QueryResult, key: &str) -> AppResult<T> {
    row.try_get("", key).map_err(db_error)
}
pub(crate) async fn lock_users(
    connection: &impl ConnectionTrait,
    a: Uuid,
    b: Uuid,
) -> AppResult<()> {
    let rows = connection
        .query_all_raw(statement(
            "SELECT id FROM users WHERE id IN ($1,$2) ORDER BY id FOR UPDATE",
            vec![a.into(), b.into()],
        ))
        .await
        .map_err(db_error)?;
    if rows.len() != 2 {
        return Err(DomainError::NotFound);
    }
    Ok(())
}
#[async_trait]
impl Health for PgStore {
    async fn ready(&self) -> AppResult<()> {
        self.database
            .query_one_raw(statement("SELECT 1", vec![]))
            .await
            .map_err(db_error)?;
        Ok(())
    }
}
