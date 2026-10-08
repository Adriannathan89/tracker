use crate::{Runtime, transport::*};
use furnace_rs::axum::{http::StatusCode, response::Response};
use furnace_rs::prelude::*;
#[controller]
pub struct HealthController {
    runtime: Runtime,
}
#[controller(route = "/health")]
impl HealthController {
    #[get("/live")]
    fn live(&self) -> Response {
        ok(
            serde_json::json!({"service":"tracker","status":"ok"}),
            StatusCode::OK,
            "OK",
        )
    }
    #[get("/ready")]
    async fn ready(&self) -> Result<Response, ApiError> {
        self.runtime.services.repository.ready().await?;
        Ok(ok(
            serde_json::json!({"modelLoaded":true}),
            StatusCode::OK,
            "Ready",
        ))
    }
}

#[cauldron]
pub(crate) struct HealthCauldron;
impl Cauldron for HealthCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.controller::<HealthController>()
    }
}
