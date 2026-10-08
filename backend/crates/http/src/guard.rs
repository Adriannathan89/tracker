use crate::Runtime;
use furnace_rs::prelude::*;
use serde::Deserialize;
use tracker_application::TokenIdentity;
use uuid::Uuid;
#[derive(Deserialize)]
pub struct SessionClaims {
    pub user_id: Uuid,
    pub session_id: Uuid,
}
pub struct SessionPrincipal {
    pub user_id: Uuid,
    pub origin_allowed: bool,
}
impl PassportPrincipal for SessionPrincipal {
    fn has_role(&self, _: &str) -> bool {
        true
    }
    fn has_permission(&self, _: &str) -> bool {
        true
    }
}
#[burner]
pub struct SessionStrategy {
    runtime: Runtime,
}
#[passport_strategy(name = "tracker-session")]
impl PassportStrategy for SessionStrategy {
    type Claims = SessionClaims;
    type Principal = SessionPrincipal;
    const TOKEN_KIND: JwtTokenKind = JwtTokenKind::Access;
    async fn validate(
        &self,
        context: &PassportContext<'_>,
        claims: &JwtClaims<Self::Claims>,
    ) -> PassportResult<Self::Principal> {
        if claims.registered.subject.as_deref() != Some(claims.custom.user_id.to_string().as_str())
            || claims.registered.issued_at > (chrono::Utc::now().timestamp() + 5) as u64
        {
            return Err(PassportError::reject());
        }
        let i = TokenIdentity {
            user_id: claims.custom.user_id,
            session_id: claims.custom.session_id,
            expires_at: i64::try_from(claims.registered.expires_at)
                .map_err(|_| PassportError::reject())?,
        };
        let user_id = self
            .runtime
            .services
            .validate(i)
            .await
            .map_err(|_| PassportError::reject())?;
        Ok(SessionPrincipal {
            user_id,
            origin_allowed: self
                .runtime
                .check_origin(context.method(), context.headers())
                .is_ok(),
        })
    }
}
#[guard(strategy="tracker-session",principal=SessionPrincipal,source=cookie("token"),predicate=origin_allowed)]
pub struct SessionGuard;

fn origin_allowed(principal: &SessionPrincipal) -> bool {
    principal.origin_allowed
}
