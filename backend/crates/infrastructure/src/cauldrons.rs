//! Framework composition adapters around framework-independent application ports.
use crate::{
    config::{TrackerSettings, framework_error},
    model::NativeClassifier,
    postgres::PgStore,
    security::Tokens,
};
use furnace_rs::{
    core::{LifecycleFuture, LifecycleResource},
    prelude::*,
};
use furnace_rs_persistence::sea_orm::{DatabaseCauldron, DatabaseConnection};
use std::sync::Arc;
use tracker_application::{Classifier, Repository, Services, TokenCodec};

impl Injector<Arc<dyn Classifier>> for NativeClassifier {
    type Dependencies = (TrackerSettings,);
    async fn inject(
        (settings,): Self::Dependencies,
    ) -> furnace_rs::core::Result<Arc<dyn Classifier>> {
        Ok(Arc::new(
            Self::load_verified(&settings.model_path).map_err(framework_error)?,
        ))
    }
}
#[cauldron]
pub struct ModelCauldron;
impl Cauldron for ModelCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.provide_with::<Arc<dyn Classifier>, NativeClassifier>()
            .export::<Arc<dyn Classifier>>()
    }
}

impl Injector for Migrations {
    type Dependencies = (DatabaseConnection,);
    async fn inject((database,): Self::Dependencies) -> furnace_rs::core::Result<Self> {
        Ok(Self { database })
    }
    fn lifecycle(value: Self) -> LifecycleResource<Self> {
        LifecycleResource::new(value.clone()).with_application_hook(value)
    }
}
#[derive(Clone)]
pub struct Migrations {
    database: DatabaseConnection,
}
impl LifecycleHook for Migrations {
    fn name(&self) -> &str {
        "tracker.migrations"
    }
    fn start<'a>(&'a self, _: &'a ApplicationContext) -> LifecycleFuture<'a> {
        Box::pin(async move {
            PgStore::migrate(&self.database)
                .await
                .map_err(framework_error)
        })
    }
    fn stop<'a>(&'a self, _: &'a ApplicationContext) -> LifecycleFuture<'a> {
        Box::pin(async { Ok(()) })
    }
}
impl Injector<Arc<dyn Repository>> for PgStore {
    type Dependencies = (PgStore,);
    async fn inject(
        (store,): <Self as Injector<Arc<dyn Repository>>>::Dependencies,
    ) -> furnace_rs::core::Result<Arc<dyn Repository>> {
        Ok(Arc::new(store))
    }
}
#[cauldron]
pub struct PersistenceCauldron;
impl Cauldron for PersistenceCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.import(DatabaseCauldron)
            .import(ModelCauldron)
            .provide::<Migrations>()
            .provide::<PgStore>()
            .provide_with::<Arc<dyn Repository>, PgStore>()
            .export::<Arc<dyn Repository>>()
            .export::<PgStore>()
            .export::<Migrations>()
    }
}
#[cauldron]
pub struct SecurityCauldron;
impl Cauldron for SecurityCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.provide_with::<Arc<dyn TokenCodec>, Tokens>()
            .export::<Arc<dyn TokenCodec>>()
    }
}

#[burner]
pub struct ApplicationBurner {
    repository: Arc<dyn Repository>,
    classifier: Arc<dyn Classifier>,
    tokens: Arc<dyn TokenCodec>,
}
impl Injector<Arc<Services>> for ApplicationBurner {
    type Dependencies = (ApplicationBurner,);
    async fn inject(
        (service,): <Self as Injector<Arc<Services>>>::Dependencies,
    ) -> furnace_rs::core::Result<Arc<Services>> {
        Ok(Arc::new(Services::new(
            service.repository.clone(),
            service.classifier.clone(),
            service.tokens.clone(),
        )))
    }
}

#[derive(Clone)]
pub struct DiscordWorker {
    store: PgStore,
    settings: TrackerSettings,
    worker: Arc<tokio::sync::Mutex<Option<crate::discord::DiscordRuntime>>>,
}
impl Injector for DiscordWorker {
    type Dependencies = (Migrations, PgStore, TrackerSettings);
    async fn inject((_, store, settings): Self::Dependencies) -> furnace_rs::core::Result<Self> {
        Ok(Self {
            store,
            settings,
            worker: Arc::new(tokio::sync::Mutex::new(None)),
        })
    }
    fn lifecycle(value: Self) -> LifecycleResource<Self> {
        LifecycleResource::new(value.clone()).with_application_hook(value)
    }
}
impl LifecycleHook for DiscordWorker {
    fn name(&self) -> &str {
        "tracker.discord"
    }
    fn start<'a>(&'a self, _: &'a ApplicationContext) -> LifecycleFuture<'a> {
        Box::pin(async move {
            if let Some(config) = self.settings.discord()? {
                *self.worker.lock().await = Some(
                    crate::discord::DiscordRuntime::start(config, self.store.clone())
                        .map_err(framework_error)?,
                );
            }
            Ok(())
        })
    }
    fn stop<'a>(&'a self, _: &'a ApplicationContext) -> LifecycleFuture<'a> {
        Box::pin(async move {
            if let Some(worker) = self.worker.lock().await.take() {
                worker.shutdown().await;
            }
            Ok(())
        })
    }
}

#[cauldron]
pub struct ApplicationCauldron;
impl Cauldron for ApplicationCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.import(crate::config::ConfigurationCauldron)
            .import(PersistenceCauldron)
            .import(ModelCauldron)
            .import(SecurityCauldron)
            .provide::<ApplicationBurner>()
            .provide_with::<Arc<Services>, ApplicationBurner>()
            .provide::<DiscordWorker>()
            .export::<Arc<Services>>()
    }
}
