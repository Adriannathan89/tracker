use crate::{
    Runtime,
    guard::{SessionGuard, SessionPrincipal},
    transport::*,
};
use furnace_rs::axum::{http::StatusCode, response::Response};
use furnace_rs::prelude::*;
use tracker_application::*;
use uuid::Uuid;
#[derive(serde::Deserialize, Input)]
struct Search {
    #[validate(length(max = 50))]
    name: String,
}
#[derive(serde::Deserialize, Input)]
#[serde(rename_all = "camelCase")]
struct Add {
    friend_id: Uuid,
}
#[derive(serde::Deserialize, Input)]
#[serde(rename_all = "camelCase")]
struct Respond {
    friend_request_id: Uuid,
    action: FriendAction,
}
#[controller]
pub struct FriendController {
    runtime: Runtime,
}
impl Sealable for FriendController {
    fn seals() -> SealRegistration<Self> {
        Self::seal::<SessionGuard>()
    }
}
#[controller(route = "/user/friend")]
impl FriendController {
    #[post("/search")]
    async fn search(
        &self,
        p: Authenticated<SessionPrincipal>,
        ValidatedJson(c): ValidatedJson<Search>,
    ) -> Result<Response, ApiError> {
        Ok(ok(
            self.runtime
                .services
                .search_friends(p.user_id, c.name)
                .await?,
            StatusCode::OK,
            "OK",
        ))
    }
    #[get]
    async fn list(&self, p: Authenticated<SessionPrincipal>) -> Result<Response, ApiError> {
        Ok(ok(
            self.runtime.services.list_friends(p.user_id).await?,
            StatusCode::OK,
            "OK",
        ))
    }
    #[get("/request")]
    async fn requests(&self, p: Authenticated<SessionPrincipal>) -> Result<Response, ApiError> {
        Ok(ok(
            self.runtime.services.requests(p.user_id).await?,
            StatusCode::OK,
            "OK",
        ))
    }
    #[post("/add")]
    async fn add(
        &self,
        p: Authenticated<SessionPrincipal>,
        ValidatedJson(c): ValidatedJson<Add>,
    ) -> Result<Response, ApiError> {
        self.runtime
            .services
            .send_request(p.user_id, c.friend_id)
            .await?;
        Ok(ok((), StatusCode::OK, "Request sent"))
    }
    #[put("/request/response")]
    async fn respond(
        &self,
        p: Authenticated<SessionPrincipal>,
        ValidatedJson(c): ValidatedJson<Respond>,
    ) -> Result<Response, ApiError> {
        self.runtime
            .services
            .respond(p.user_id, c.friend_request_id, c.action)
            .await?;
        Ok(ok((), StatusCode::OK, "Request handled"))
    }
}

#[cauldron]
pub(crate) struct FriendsCauldron;
impl Cauldron for FriendsCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.controller::<FriendController>()
    }
}
