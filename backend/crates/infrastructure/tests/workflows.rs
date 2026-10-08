//! Run explicitly against a disposable PostgreSQL database with a name ending `_test`.
use rust_decimal::Decimal;
use sea_orm::{ConnectionTrait, DbBackend, Statement};
use std::{path::PathBuf, sync::Arc};
use tracker_application::*;
use tracker_infrastructure::{model::NativeClassifier, postgres::PgStore, security::Tokens};
use uuid::Uuid;
async fn setup() -> (Arc<Services>, Uuid, Uuid) {
    let url = std::env::var("TRACKER_TEST_DATABASE_URL")
        .expect("set TRACKER_TEST_DATABASE_URL to a disposable *_test database");
    let options: sqlx::postgres::PgConnectOptions = url.parse().expect("valid PostgreSQL test URL");
    assert!(
        options
            .get_database()
            .is_some_and(|name| name.ends_with("_test")),
        "database name must end in _test"
    );
    let store = PgStore::connect(&url, model()).await.unwrap();
    let svc = Arc::new(Services::new(
        Arc::new(store),
        model(),
        Arc::new(Tokens::new("test-only-secret-32-characters-long".into()).unwrap()),
    ));
    let a = svc
        .register(Credentials {
            username: format!("a{}", Uuid::new_v4()),
            password: "password123".into(),
        })
        .await
        .unwrap();
    let b = svc
        .register(Credentials {
            username: format!("b{}", Uuid::new_v4()),
            password: "password123".into(),
        })
        .await
        .unwrap();
    (svc, a.id, b.id)
}
fn model() -> Arc<NativeClassifier> {
    Arc::new(
        NativeClassifier::load(
            &PathBuf::from(env!("CARGO_MANIFEST_DIR"))
                .join("../../../models/transaction-model.json"),
        )
        .unwrap(),
    )
}
async fn draft(s: &Services, id: Uuid) -> Record {
    s.create_record(
        id,
        CreateRecord {
            title: "makan siang".into(),
            description: "test".into(),
            amount: Decimal::from(100),
            date: chrono::Utc::now().date_naive(),
        },
    )
    .await
    .unwrap()
}
fn commit(id: Uuid) -> CommitRecord {
    CommitRecord {
        record_id: id,
        category: Some("makanan".into()),
        secondary_category: Some("jajanan".into()),
    }
}
#[tokio::test]
#[ignore = "requires disposable PostgreSQL *_test database"]
async fn commit_twice_changes_cash_once_and_secondary_only_correction_persists() {
    let (s, a, _) = setup().await;
    let r = draft(&s, a).await;
    let r = s
        .repository
        .commit_record(
            a,
            CommitRecord {
                record_id: r.id,
                category: None,
                secondary_category: Some("jajanan".into()),
            },
        )
        .await
        .unwrap();
    assert!(r.is_committed);
    assert!(r.categories.iter().any(|c| c.name == "jajanan"));
    assert!(matches!(
        s.repository.commit_record(a, commit(r.id)).await,
        Err(DomainError::Conflict(_))
    ));
    assert_eq!(
        s.repository.list_records(a).await.unwrap().cash,
        Decimal::from(-100)
    );
    assert!(s.repository.delete_draft(a, r.id).await.is_err());
}
#[tokio::test]
#[ignore = "requires disposable PostgreSQL *_test database"]
async fn concurrent_commit_changes_cash_once() {
    let (s, a, _) = setup().await;
    let r = draft(&s, a).await;
    let (x, y) = tokio::join!(
        s.repository.commit_record(a, commit(r.id)),
        s.repository.commit_record(a, commit(r.id))
    );
    assert_ne!(x.is_ok(), y.is_ok());
    assert_eq!(
        s.repository.list_records(a).await.unwrap().cash,
        Decimal::from(-100)
    );
}
#[tokio::test]
#[ignore = "requires disposable PostgreSQL *_test database"]
async fn ownership_and_invalid_category_roll_back() {
    let (s, a, b) = setup().await;
    let r = draft(&s, a).await;
    assert!(s.repository.commit_record(b, commit(r.id)).await.is_err());
    assert!(s.repository.delete_draft(b, r.id).await.is_err());
    assert!(
        s.repository
            .commit_record(
                a,
                CommitRecord {
                    record_id: r.id,
                    category: Some("unknown".into()),
                    secondary_category: None
                }
            )
            .await
            .is_err()
    );
    assert_eq!(
        s.repository.list_records(a).await.unwrap().cash,
        Decimal::ZERO
    );
    s.repository.delete_draft(a, r.id).await.unwrap();
}
#[tokio::test]
#[ignore = "requires disposable PostgreSQL *_test database"]
async fn debts_settle_once_and_generated_records_are_committed() {
    let (s, a, b) = setup().await;
    let d = s
        .create_debt(
            a,
            CreateDebt {
                amount: Decimal::from(100),
                description: "loan".into(),
                debtor_id: b,
            },
        )
        .await
        .unwrap();
    assert!(matches!(
        s.repository.finish_debt(a, d.id).await,
        Err(DomainError::Forbidden)
    ));
    let (x, y) = tokio::join!(
        s.repository.finish_debt(b, d.id),
        s.repository.finish_debt(b, d.id)
    );
    assert_ne!(x.is_ok(), y.is_ok());
    let owner = s.repository.list_records(a).await.unwrap();
    let debtor = s.repository.list_records(b).await.unwrap();
    assert_eq!(owner.cash, Decimal::ZERO);
    assert_eq!(owner.receivable, Decimal::ZERO);
    assert_eq!(debtor.cash, Decimal::from(-100));
    assert_eq!(debtor.debt, Decimal::ZERO);
    assert!(
        owner
            .expenses
            .iter()
            .chain(&owner.incomes)
            .all(|r| r.is_committed)
    );
}
#[tokio::test]
#[ignore = "requires disposable PostgreSQL *_test database"]
async fn friends_accept_and_reject_enforce_receiver() {
    let (s, a, b) = setup().await;
    let name = s.get_profile(b).await.unwrap().username;
    assert_eq!(
        s.search_friends(a, name).await.unwrap()[0].status,
        "not_friend"
    );
    s.repository.send_request(a, b).await.unwrap();
    assert!(s.repository.send_request(b, a).await.is_err());
    assert!(s.repository.send_request(a, a).await.is_err());
    let q = s.repository.requests(b).await.unwrap()[0].id;
    assert!(matches!(
        s.repository.respond(a, q, FriendAction::Accept).await,
        Err(DomainError::Forbidden)
    ));
    s.repository
        .respond(b, q, FriendAction::Accept)
        .await
        .unwrap();
    assert_eq!(s.repository.list_friends(a).await.unwrap()[0].id, b);
    assert_eq!(s.repository.list_friends(b).await.unwrap()[0].id, a);
}
#[tokio::test]
#[ignore = "requires disposable PostgreSQL *_test database"]
async fn register_login_logout_and_rename_preserves_session() {
    let (s, a, _) = setup().await;
    let profile = s.repository.get_profile(a).await.unwrap();
    let (_, tokens) = s
        .login(Credentials {
            username: profile.username,
            password: "password123".into(),
        })
        .await
        .unwrap();
    let id = s.tokens.verify_access(&tokens.access).unwrap();
    s.rename(a, format!("new{}", Uuid::new_v4())).await.unwrap();
    assert_eq!(s.validate(id.clone()).await.unwrap(), a);
    s.logout(&tokens.refresh).await.unwrap();
    assert!(s.validate(id).await.is_err());
}

#[tokio::test]
#[ignore = "requires disposable PostgreSQL *_test database"]
async fn expired_and_reused_code_rejected_and_weekly_restart_deduplicates() {
    let (s, a, _) = setup().await;
    let code = s.generate_code(a).await.unwrap();
    s.verify_code(
        code.code.clone(),
        "12345678901234567".into(),
        "discord-user".into(),
    )
    .await
    .unwrap();
    assert!(
        s.verify_code(code.code, "12345678901234567".into(), "discord-user".into())
            .await
            .is_err()
    );
    let profile = s.get_profile(a).await.unwrap();
    assert!(profile.discord.connected);
    s.set_notification(a, NotificationKind::Commit, false)
        .await
        .unwrap();
    assert!(!s.get_profile(a).await.unwrap().discord.commit_notif_enabled);
    let url = std::env::var("TRACKER_TEST_DATABASE_URL").unwrap();
    let store = PgStore::connect(&url, model()).await.unwrap();
    let next = s.generate_code(a).await.unwrap();
    store.database().execute_raw(Statement::from_sql_and_values(DbBackend::Postgres, "UPDATE discord_verifications SET expires_at=NOW()-INTERVAL '1 minute' WHERE user_id=$1", vec![(a).into()]))
    .await
    .unwrap();
    assert!(
        s.verify_code(next.code, "12345678901234567".into(), "discord-user".into())
            .await
            .is_err()
    );
    let key = format!("test-week-{}", Uuid::new_v4());
    assert!(
        tracker_infrastructure::discord::enqueue_weekly_report(&store, a, &key, "test report")
            .await
            .unwrap()
    );
    let restarted = PgStore::connect(&url, model()).await.unwrap();
    assert!(
        !tracker_infrastructure::discord::enqueue_weekly_report(&restarted, a, &key, "test report")
            .await
            .unwrap()
    );
    s.disconnect(a).await.unwrap();
    assert!(!s.discord_status(a).await.unwrap().verified);
}
