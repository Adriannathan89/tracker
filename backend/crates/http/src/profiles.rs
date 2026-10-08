use crate::{
    Runtime,
    guard::{SessionGuard, SessionPrincipal},
    transport::*,
};
use furnace_rs::axum::{
    body::Bytes,
    http::{HeaderMap, StatusCode},
    response::Response,
};
use furnace_rs::prelude::*;
use tracker_application::*;
#[derive(serde::Deserialize, Input)]
struct Rename {
    #[validate(length(min = 3, max = 50))]
    username: String,
}
#[derive(serde::Deserialize, Input)]
struct Notification {
    #[serde(rename = "type")]
    kind: NotificationKind,
    enabled: bool,
}
#[controller]
pub struct ProfileController {
    runtime: Runtime,
}
impl Sealable for ProfileController {
    fn seals() -> SealRegistration<Self> {
        Self::seal::<SessionGuard>()
    }
}
#[controller(route = "/user")]
impl ProfileController {
    #[get("/profile")]
    async fn get(&self, p: Authenticated<SessionPrincipal>) -> Result<Response, ApiError> {
        Ok(ok(
            self.runtime.services.get_profile(p.user_id).await?,
            StatusCode::OK,
            "OK",
        ))
    }
    #[put("/profile")]
    async fn update(
        &self,
        p: Authenticated<SessionPrincipal>,
        ValidatedJson(c): ValidatedJson<Rename>,
    ) -> Result<Response, ApiError> {
        Ok(ok(
            self.runtime.services.rename(p.user_id, c.username).await?,
            StatusCode::OK,
            "OK",
        ))
    }
    #[post("/discord/verify")]
    async fn code(&self, p: Authenticated<SessionPrincipal>) -> Result<Response, ApiError> {
        let cfg = self
            .runtime
            .discord
            .as_ref()
            .ok_or(DomainError::Unavailable)?;
        let v = self.runtime.services.generate_code(p.user_id).await?;
        Ok(ok(
            serde_json::json!({"code":v.code,"expiresAt":v.expires_at,"botUsername":cfg.username,"installUrl":format!("https://discord.com/oauth2/authorize?client_id={}&scope=applications.commands+bot&integration_type=1",cfg.application_id)}),
            StatusCode::OK,
            "Code generated",
        ))
    }
    #[get("/discord/status")]
    async fn status(&self, p: Authenticated<SessionPrincipal>) -> Result<Response, ApiError> {
        Ok(ok(
            self.runtime.services.discord_status(p.user_id).await?,
            StatusCode::OK,
            "OK",
        ))
    }
    #[delete("/discord")]
    async fn disconnect(&self, p: Authenticated<SessionPrincipal>) -> Result<Response, ApiError> {
        self.runtime.services.disconnect(p.user_id).await?;
        Ok(ok((), StatusCode::OK, "Disconnected"))
    }
    #[put("/discord/notification")]
    async fn notification(
        &self,
        p: Authenticated<SessionPrincipal>,
        ValidatedJson(c): ValidatedJson<Notification>,
    ) -> Result<Response, ApiError> {
        self.runtime
            .services
            .set_notification(p.user_id, c.kind, c.enabled)
            .await?;
        Ok(ok((), StatusCode::OK, "OK"))
    }
}
#[controller]
pub struct InteractionController {
    runtime: Runtime,
}
#[controller(route = "/discord")]
impl InteractionController {
    #[post("/interactions")]
    async fn interaction(
        &self,
        headers: HeaderMap,
        body: Bytes,
    ) -> Result<Json<serde_json::Value>, ApiError> {
        let cfg = self
            .runtime
            .discord
            .as_ref()
            .ok_or(DomainError::Unavailable)?;
        let signature = headers
            .get("x-signature-ed25519")
            .and_then(|v| v.to_str().ok())
            .ok_or(DomainError::Unauthorized)?;
        let timestamp = headers
            .get("x-signature-timestamp")
            .and_then(|v| v.to_str().ok())
            .ok_or(DomainError::Unauthorized)?;
        tracker_infrastructure::discord::verify_signature(
            &cfg.public_key,
            signature,
            timestamp,
            &body,
            chrono::Utc::now().timestamp(),
        )?;
        let value: serde_json::Value = serde_json::from_slice(&body)
            .map_err(|_| DomainError::Validation("Invalid interaction".into()))?;
        if value["type"] == 1 {
            return Ok(Json(serde_json::json!({"type":1})));
        }
        if value["application_id"].as_str() != Some(cfg.application_id.as_str())
            || value["type"] != 2
            || value["data"]["name"] != "verify"
        {
            return Err(DomainError::Validation("Unsupported interaction".into()).into());
        }
        let user = value
            .get("user")
            .or_else(|| value.get("member").and_then(|m| m.get("user")))
            .ok_or(DomainError::Unauthorized)?;
        let id = user["id"]
            .as_str()
            .ok_or(DomainError::Unauthorized)?
            .to_owned();
        let name = user["username"]
            .as_str()
            .ok_or(DomainError::Unauthorized)?
            .to_owned();
        let code = value["data"]["options"]
            .as_array()
            .and_then(|a| a.iter().find(|v| v["name"] == "code"))
            .and_then(|v| v["value"].as_str())
            .ok_or_else(|| DomainError::Validation("Code required".into()))?
            .to_owned();
        let result = tokio::time::timeout(
            std::time::Duration::from_secs(2),
            self.runtime.services.verify_code(code, id, name),
        )
        .await;
        let message = match result {
            Ok(Ok(())) => "Akun Discord berhasil terhubung ke Tracker.",
            Ok(Err(DomainError::Validation(_))) => "Kode salah, sudah dipakai, atau kedaluwarsa.",
            _ => "Verifikasi gagal. Silakan coba lagi.",
        };
        Ok(Json(
            serde_json::json!({"type":4,"data":{"content":message,"flags":64,"allowed_mentions":{"parse":[]}}}),
        ))
    }
}

#[cauldron]
pub(crate) struct ProfilesCauldron;
impl Cauldron for ProfilesCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.controller::<ProfileController>()
            .controller::<InteractionController>()
    }
}
