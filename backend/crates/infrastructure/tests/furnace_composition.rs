use furnace_rs::prelude::*;
use furnace_rs_persistence::sea_orm::DatabaseConnection;
use std::sync::Arc;
use tracker_application::{AppResult, Classification, Classifier, DomainError};
use tracker_infrastructure::{cauldrons::ApplicationCauldron, postgres::PgStore};

struct UnusedClassifier;
impl Classifier for UnusedClassifier {
    fn classify(&self, _: &str) -> AppResult<Classification> {
        Err(DomainError::Unavailable)
    }
    fn validate_categories(&self, _: &str, _: &str) -> AppResult<()> {
        Err(DomainError::Unavailable)
    }
}

#[tokio::test]
async fn repository_and_native_database_share_the_same_pool_and_close_state() {
    let pool = sqlx::postgres::PgPoolOptions::new()
        .connect_lazy("postgresql://tracker:password@localhost/tracker_test")
        .unwrap();
    let database: DatabaseConnection =
        sea_orm::SqlxPostgresConnector::from_sqlx_postgres_pool(pool);
    let store = <PgStore as Injector>::inject((database.clone(), Arc::new(UnusedClassifier)))
        .await
        .unwrap();
    assert!(!database.get_postgres_connection_pool().is_closed());
    store.database().clone().close().await.unwrap();
    assert!(database.get_postgres_connection_pool().is_closed());
}

#[test]
fn native_graph_selects_one_database_and_auto_configures_jwt_without_connecting() {
    let config = ConfigBuilder::new()
        .source(furnace_rs::core::MapSource::new(
            "test",
            [
                ("passport.secret", "test-only-secret-32-characters-long"),
                ("tracker.public_origin", "http://localhost:8080"),
                ("tracker.model_path", "/unused/model.json"),
                (
                    "persistence.seaorm.url",
                    "postgresql://unused:unused@localhost/unused",
                ),
            ],
        ))
        .build()
        .unwrap();
    let mut builder = Furnace::builder_with_config(config);
    builder.root::<ApplicationCauldron>().unwrap();
    let analysis = builder.analyze();
    assert!(analysis.is_valid(), "{:?}", analysis.diagnostics());
    assert_eq!(
        analysis
            .graph()
            .providers()
            .iter()
            .filter(|p| p.type_name().ends_with("DatabaseConnection"))
            .count(),
        1
    );
    assert!(
        analysis
            .graph()
            .providers()
            .iter()
            .any(|p| p.type_name().ends_with("::PgStore")
                && p.origin() == ProviderOrigin::Repository)
    );
    assert!(
        analysis
            .graph()
            .providers()
            .iter()
            .any(|p| p.type_name().ends_with("::ApplicationBurner")
                && p.origin() == ProviderOrigin::Service)
    );
    assert!(
        analysis
            .graph()
            .providers()
            .iter()
            .any(|p| p.type_name().ends_with("JwtService")
                && p.origin() == ProviderOrigin::AutoConfiguration)
    );
}
