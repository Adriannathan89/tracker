use crate::input::{CommitRecordInput, CreateRecordInput};
use crate::{
    Runtime,
    guard::{SessionGuard, SessionPrincipal},
    transport::*,
};
use furnace_rs::axum::{http::StatusCode, response::Response};
use furnace_rs::prelude::*;
use uuid::Uuid;
#[controller]
pub struct RecordController {
    runtime: Runtime,
}
impl Sealable for RecordController {
    fn seals() -> SealRegistration<Self> {
        Self::seal::<SessionGuard>()
    }
}
#[controller(route = "/user")]
impl RecordController {
    #[post("/record")]
    async fn create(
        &self,
        p: Authenticated<SessionPrincipal>,
        ValidatedJson(c): ValidatedJson<CreateRecordInput>,
    ) -> Result<Response, ApiError> {
        Ok(ok(
            self.runtime
                .services
                .create_record(p.user_id, c.into())
                .await?,
            StatusCode::OK,
            "Record created successfully",
        ))
    }
    #[get("/records")]
    async fn list(&self, p: Authenticated<SessionPrincipal>) -> Result<Response, ApiError> {
        Ok(ok(
            self.runtime.services.list_records(p.user_id).await?,
            StatusCode::OK,
            "Transactions loaded successfully",
        ))
    }
    #[put("/record/commit")]
    async fn commit(
        &self,
        p: Authenticated<SessionPrincipal>,
        ValidatedJson(c): ValidatedJson<CommitRecordInput>,
    ) -> Result<Response, ApiError> {
        Ok(ok(
            self.runtime
                .services
                .commit_record(p.user_id, c.into())
                .await?,
            StatusCode::OK,
            "Record committed",
        ))
    }
    #[delete("/record/:id")]
    async fn delete(
        &self,
        p: Authenticated<SessionPrincipal>,
        Path(id): Path<Uuid>,
    ) -> Result<Response, ApiError> {
        self.runtime.services.delete_draft(p.user_id, id).await?;
        Ok(ok((), StatusCode::OK, "Record deleted"))
    }
}

#[cauldron]
pub(crate) struct RecordsCauldron;
impl Cauldron for RecordsCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.controller::<RecordController>()
    }
}
