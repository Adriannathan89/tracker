use sea_orm::{DbBackend, DbErr, MockDatabase, MockExecResult, Value};
use sha2::{Digest, Sha256};
use std::collections::BTreeMap;
use tracker_application::DomainError;
use tracker_infrastructure::postgres::PgStore;

type Row = BTreeMap<String, Value>;
const SCHEMA: &str = include_str!("../../../migrations/0001_tracker.sql");
fn checksum_row(checksum: String) -> Row {
    BTreeMap::from([("checksum".into(), checksum.into())])
}
fn executed() -> MockExecResult {
    MockExecResult {
        last_insert_id: 0,
        rows_affected: 1,
    }
}

#[tokio::test]
async fn fresh_schema_and_checksum_commit_in_one_serialized_transaction() {
    let database = MockDatabase::new(DbBackend::Postgres)
        .append_query_results([Vec::<Row>::new(), Vec::new()])
        .append_exec_results([executed(), executed(), executed()])
        .into_connection();
    PgStore::migrate(&database).await.unwrap();
    let log = database.into_transaction_log();
    assert_eq!(log.len(), 1);
    let statements = log[0].statements();
    assert_eq!(statements.first().unwrap().sql, "BEGIN");
    assert!(statements[1].sql.contains("pg_advisory_xact_lock"));
    assert_eq!(statements[4].sql, SCHEMA);
    assert!(
        statements[5]
            .sql
            .starts_with("INSERT INTO tracker_migrations")
    );
    assert_eq!(statements.last().unwrap().sql, "COMMIT");
}

#[tokio::test]
async fn existing_matching_schema_is_not_reapplied() {
    let database = MockDatabase::new(DbBackend::Postgres)
        .append_query_results([
            vec![],
            vec![checksum_row(format!("{:x}", Sha256::digest(SCHEMA)))],
        ])
        .append_exec_results([executed()])
        .into_connection();
    PgStore::migrate(&database).await.unwrap();
    let log = database.into_transaction_log();
    let statements = log[0].statements();
    assert_eq!(statements.len(), 5);
    assert_eq!(statements.last().unwrap().sql, "COMMIT");
}

#[tokio::test]
async fn changed_schema_checksum_rejects_startup_and_rolls_back() {
    let database = MockDatabase::new(DbBackend::Postgres)
        .append_query_results([vec![], vec![checksum_row("tampered".into())]])
        .append_exec_results([executed()])
        .into_connection();
    assert!(matches!(
        PgStore::migrate(&database).await,
        Err(DomainError::Validation(_))
    ));
    let log = database.into_transaction_log();
    assert_eq!(log[0].statements().last().unwrap().sql, "ROLLBACK");
}

#[tokio::test]
async fn schema_failure_does_not_record_a_successful_migration() {
    let database = MockDatabase::new(DbBackend::Postgres)
        .append_query_results([Vec::<Row>::new(), Vec::new()])
        .append_exec_results([executed()])
        .append_exec_errors([DbErr::Custom("schema failure".into())])
        .into_connection();
    assert!(matches!(
        PgStore::migrate(&database).await,
        Err(DomainError::Unavailable)
    ));
    let log = database.into_transaction_log();
    assert_eq!(log[0].statements().last().unwrap().sql, "ROLLBACK");
    assert!(
        !log[0]
            .statements()
            .iter()
            .any(|s| s.sql.starts_with("INSERT INTO tracker_migrations"))
    );
}
