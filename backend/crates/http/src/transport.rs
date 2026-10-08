use furnace_rs::axum::{
    Json,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use furnace_rs::prelude::{Cookie, CookieJar, SameSite};
use serde::Serialize;
use tracker_application::{DomainError, TokenPair};
#[derive(Debug)]
pub struct ApiError(pub DomainError);
impl From<DomainError> for ApiError {
    fn from(e: DomainError) -> Self {
        Self(e)
    }
}
impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let status = match self.0 {
            DomainError::Validation(_) => StatusCode::BAD_REQUEST,
            DomainError::Unauthorized => StatusCode::UNAUTHORIZED,
            DomainError::Forbidden => StatusCode::FORBIDDEN,
            DomainError::NotFound => StatusCode::NOT_FOUND,
            DomainError::Conflict(_) => StatusCode::CONFLICT,
            DomainError::Unavailable => StatusCode::SERVICE_UNAVAILABLE,
        };
        (status,Json(serde_json::json!({"status":status.as_u16(),"message":self.0.to_string(),"data":null}))).into_response()
    }
}
/// Keeps native validation rejection responses intact at public auth boundaries.
pub struct RequestError(Box<Response>);
impl From<Response> for RequestError {
    fn from(response: Response) -> Self {
        Self(Box::new(response))
    }
}
impl From<ApiError> for RequestError {
    fn from(error: ApiError) -> Self {
        error.into_response().into()
    }
}
impl From<DomainError> for RequestError {
    fn from(error: DomainError) -> Self {
        ApiError(error).into()
    }
}
impl IntoResponse for RequestError {
    fn into_response(self) -> Response {
        *self.0
    }
}
pub fn ok<T: Serialize>(data: T, status: StatusCode, message: &str) -> Response {
    (
        status,
        Json(serde_json::json!({"status":status.as_u16(),"message":message,"data":data})),
    )
        .into_response()
}
fn session_cookie(name: &str, value: &str, age: i64, secure: bool) -> Cookie<'static> {
    Cookie::build((name.to_owned(), value.to_owned()))
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .secure(secure)
        .max_age(furnace_rs::cookie::time::Duration::seconds(age))
        .build()
}
pub fn cookies(response: Response, pair: &TokenPair, secure: bool) -> Response {
    (
        CookieJar::new()
            .add(session_cookie("token", &pair.access, 600, secure))
            .add(session_cookie(
                "refresh_token",
                &pair.refresh,
                30 * 86400,
                secure,
            )),
        response,
    )
        .into_response()
}
pub fn clear_cookies(response: Response, secure: bool) -> Response {
    (
        CookieJar::new()
            .add(session_cookie("token", "", 0, secure))
            .add(session_cookie("refresh_token", "", 0, secure)),
        response,
    )
        .into_response()
}
