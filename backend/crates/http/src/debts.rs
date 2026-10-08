use crate::input::CreateDebtInput;
use crate::{
    Runtime,
    guard::{SessionGuard, SessionPrincipal},
    transport::*,
};
use furnace_rs::axum::{http::StatusCode, response::Response};
use furnace_rs::prelude::*;
use uuid::Uuid;
#[derive(serde::Deserialize, Input)]
#[serde(rename_all = "camelCase")]
struct FinishDebt {
    debt_id: Uuid,
}
#[controller]
pub struct DebtController {
    runtime: Runtime,
}
impl Sealable for DebtController {
    fn seals() -> SealRegistration<Self> {
        Self::seal::<SessionGuard>()
    }
}
#[controller(route = "/debt")]
impl DebtController {
    #[post("/create")]
    async fn create(
        &self,
        p: Authenticated<SessionPrincipal>,
        ValidatedJson(c): ValidatedJson<CreateDebtInput>,
    ) -> Result<Response, ApiError> {
        Ok(ok(
            self.runtime
                .services
                .create_debt(p.user_id, c.into())
                .await?,
            StatusCode::OK,
            "Debt created successfully",
        ))
    }
    #[put("/finish")]
    async fn finish(
        &self,
        p: Authenticated<SessionPrincipal>,
        ValidatedJson(c): ValidatedJson<FinishDebt>,
    ) -> Result<Response, ApiError> {
        Ok(ok(
            self.runtime
                .services
                .finish_debt(p.user_id, c.debt_id)
                .await?,
            StatusCode::OK,
            "Debt finished successfully",
        ))
    }
    #[get]
    async fn owned(&self, p: Authenticated<SessionPrincipal>) -> Result<Response, ApiError> {
        Ok(ok(
            serde_json::json!({"debts":self.runtime.services.list_debts(p.user_id,false).await?}),
            StatusCode::OK,
            "Debts loaded successfully",
        ))
    }
    #[get("/owed")]
    async fn owed(&self, p: Authenticated<SessionPrincipal>) -> Result<Response, ApiError> {
        Ok(ok(
            serde_json::json!({"debts":self.runtime.services.list_debts(p.user_id,true).await?}),
            StatusCode::OK,
            "Owed debts loaded successfully",
        ))
    }
}

#[cauldron]
pub(crate) struct DebtsCauldron;
impl Cauldron for DebtsCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.controller::<DebtController>()
    }
}
