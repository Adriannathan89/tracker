mod auth;
mod debts;
mod friends;
mod guard;
mod health;
mod input;
mod profiles;
mod records;
pub mod transport;
use furnace_rs::axum::{
    extract::{FromRequest, Request},
    http::{HeaderMap, Method},
};
use furnace_rs::prelude::*;
use std::sync::Arc;
use tracker_application::{DomainError, Services};
use tracker_infrastructure::{cauldrons::ApplicationCauldron, config::TrackerSettings};

#[derive(Clone)]
pub struct Runtime {
    pub services: Arc<Services>,
    pub origin: String,
    pub secure_cookies: bool,
    pub discord: Option<tracker_infrastructure::discord::DiscordConfig>,
}
impl Runtime {
    pub fn new(
        services: Arc<Services>,
        origin: String,
        secure_cookies: bool,
        discord: Option<tracker_infrastructure::discord::DiscordConfig>,
    ) -> Self {
        Self {
            services,
            origin,
            secure_cookies,
            discord,
        }
    }
}
impl Runtime {
    pub(crate) fn check_origin(
        &self,
        method: &Method,
        headers: &HeaderMap,
    ) -> Result<(), transport::ApiError> {
        if matches!(*method, Method::GET | Method::HEAD | Method::OPTIONS) {
            return Ok(());
        }
        if headers.get_all("origin").iter().count() > 1
            || headers
                .get("origin")
                .is_some_and(|v| v.to_str().ok() != Some(self.origin.as_str()))
            || headers
                .get("sec-fetch-site")
                .is_some_and(|v| v == "cross-site")
        {
            return Err(transport::ApiError(DomainError::Forbidden));
        }
        Ok(())
    }
    pub(crate) async fn json<T: serde::de::DeserializeOwned + Input>(
        &self,
        request: Request,
    ) -> Result<T, transport::RequestError> {
        self.check_origin(request.method(), request.headers())?;
        Ok(ValidatedJson::<T>::from_request(request, &())
            .await
            .map_err(transport::RequestError::from)?
            .0)
    }
}
impl Injector for Runtime {
    type Dependencies = (Arc<Services>, TrackerSettings);
    async fn inject((services, settings): Self::Dependencies) -> furnace_rs::core::Result<Self> {
        let discord = settings.discord()?;
        Ok(Self::new(
            services,
            settings.public_origin,
            settings.cookie_secure,
            discord,
        ))
    }
}
#[cauldron]
struct HttpServicesCauldron;
impl Cauldron for HttpServicesCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.import(ApplicationCauldron)
            .provide::<Runtime>()
            .export::<Runtime>()
            .global()
    }
}
#[cauldron]
struct SessionCauldron;
impl Cauldron for SessionCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.provide::<guard::SessionStrategy>()
            .export::<guard::SessionStrategy>()
            .global()
    }
}
#[cauldron]
pub struct TrackerCauldron;
impl Cauldron for TrackerCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.import(HttpServicesCauldron)
            .import(SessionCauldron)
            .import(auth::AuthCauldron)
            .import(records::RecordsCauldron)
            .import(debts::DebtsCauldron)
            .import(friends::FriendsCauldron)
            .import(profiles::ProfilesCauldron)
            .import(health::HealthCauldron)
    }
}
