use crate::input::{LoginInput, RegisterInput};
use crate::{
    Runtime,
    guard::{SessionGuard, SessionPrincipal},
    transport::*,
};
use furnace_rs::axum::response::IntoResponse;
use furnace_rs::axum::{http::StatusCode, response::Response};
use furnace_rs::prelude::*;
use tracker_application::*;
#[controller]
pub struct AuthController {
    runtime: Runtime,
}
impl Sealable for AuthController {
    fn seals() -> SealRegistration<Self> {
        Self::seal::<SessionGuard>()
    }
}
#[controller]
impl AuthController {
    #[post("/user/register")]
    #[seal(skip)]
    async fn register(&self, request: Request) -> Result<Response, RequestError> {
        let c: RegisterInput = self.runtime.json(request).await?;
        Ok(ok(
            self.runtime.services.register(c.into()).await?,
            StatusCode::CREATED,
            "User created successfully",
        ))
    }
    #[post("/auth/login")]
    #[seal(skip)]
    async fn login(&self, request: Request) -> Result<Response, RequestError> {
        let c: LoginInput = self.runtime.json(request).await?;
        let (user, pair) = self.runtime.services.login(c.into()).await?;
        let response = ok(user, StatusCode::OK, "Login successful");
        Ok(cookies(response, &pair, self.runtime.secure_cookies))
    }
    fn request_cookies(&self, request: &Request) -> Result<CookieJar, RequestError> {
        self.runtime
            .check_origin(request.method(), request.headers())?;
        CookieJar::from_headers(request.headers()).map_err(|_| {
            RequestError::from(BadRequest::new("Invalid cookie request").into_response())
        })
    }
    #[post("/auth/refresh")]
    #[seal(skip)]
    async fn refresh(&self, request: Request) -> Result<Response, RequestError> {
        let jar = self.request_cookies(&request)?;
        if jar.occurrences("refresh_token") != 1 {
            return Err(DomainError::Unauthorized.into());
        }
        let token = jar
            .get("refresh_token")
            .ok_or(DomainError::Unauthorized)?
            .value();
        let (_, pair) = self.runtime.services.refresh(token).await?;
        Ok(cookies(
            ok((), StatusCode::OK, "Session refreshed"),
            &pair,
            self.runtime.secure_cookies,
        ))
    }
    #[post("/auth/logout")]
    #[seal(skip)]
    async fn logout(&self, request: Request) -> Result<Response, RequestError> {
        let jar = self.request_cookies(&request)?;
        if jar.occurrences("refresh_token") > 1 {
            return Err(DomainError::Unauthorized.into());
        }
        self.runtime
            .services
            .logout(jar.get("refresh_token").map(|c| c.value()).unwrap_or(""))
            .await?;
        Ok(clear_cookies(
            ok((), StatusCode::OK, "Logout successful"),
            self.runtime.secure_cookies,
        ))
    }
    #[get("/auth/validate-session")]
    async fn validate(&self, _: Authenticated<SessionPrincipal>) -> Response {
        ok((), StatusCode::OK, "Session is still valid")
    }
}

#[cauldron]
pub(crate) struct AuthCauldron;
impl Cauldron for AuthCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.controller::<AuthController>()
    }
}
