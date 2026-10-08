#![allow(unused_variables)]
use furnace_rs::axum::{
    body::{Body, to_bytes},
    http::{Request, StatusCode},
};
use furnace_rs::prelude::{ConfigBuilder, Furnace, build_router, configure_router};
use std::{
    collections::HashMap,
    path::PathBuf,
    sync::{Arc, Mutex},
};
use tower::ServiceExt;
use tracker_application::*;
use tracker_http::TrackerCauldron;
use tracker_infrastructure::{model::NativeClassifier, security::Tokens};
use uuid::Uuid;
struct Memory {
    sessions: Mutex<HashMap<Uuid, Session>>,
}
#[allow(unused_variables)]
#[async_trait::async_trait]
impl AuthRepository for Memory {
    async fn create_user(&self, c: Credentials) -> AppResult<UserSummary> {
        Ok(UserSummary {
            id: Uuid::from_u128(1),
            username: c.username,
        })
    }
    async fn authenticate(&self, c: Credentials) -> AppResult<UserSummary> {
        if c.password == "password123" {
            Ok(UserSummary {
                id: Uuid::from_u128(1),
                username: c.username,
            })
        } else {
            Err(DomainError::Unauthorized)
        }
    }
    async fn save_session(&self, s: Session) -> AppResult<()> {
        self.sessions.lock().unwrap().insert(s.id, s);
        Ok(())
    }
    async fn get_session(&self, id: Uuid) -> AppResult<Session> {
        self.sessions
            .lock()
            .unwrap()
            .get(&id)
            .cloned()
            .ok_or(DomainError::Unauthorized)
    }
    async fn revoke_session(&self, id: Uuid) -> AppResult<()> {
        self.sessions.lock().unwrap().remove(&id);
        Ok(())
    }
}
#[async_trait::async_trait]
impl ProfileRepository for Memory {
    async fn get_profile(&self, id: Uuid) -> AppResult<Profile> {
        Ok(Profile {
            id,
            username: "tracker-user".into(),
            discord: DiscordProfile {
                connected: false,
                username: String::new(),
                commit_notif_enabled: true,
                weekly_notif_enabled: true,
            },
        })
    }
    async fn rename(&self, id: Uuid, name: String) -> AppResult<Profile> {
        Err(DomainError::Unavailable)
    }
}
#[async_trait::async_trait]
impl RecordRepository for Memory {
    async fn create_record(
        &self,
        id: Uuid,
        c: CreateRecord,
        p: Classification,
    ) -> AppResult<Record> {
        Err(DomainError::Unavailable)
    }
    async fn list_records(&self, id: Uuid) -> AppResult<RecordOverview> {
        Err(DomainError::Unavailable)
    }
    async fn commit_record(&self, id: Uuid, c: CommitRecord) -> AppResult<Record> {
        Err(DomainError::Unavailable)
    }
    async fn delete_draft(&self, id: Uuid, record: Uuid) -> AppResult<()> {
        Err(DomainError::Unavailable)
    }
}
#[async_trait::async_trait]
impl FriendRepository for Memory {
    async fn search_friends(&self, id: Uuid, name: String) -> AppResult<Vec<Friend>> {
        Err(DomainError::Unavailable)
    }
    async fn list_friends(&self, id: Uuid) -> AppResult<Vec<Friend>> {
        Err(DomainError::Unavailable)
    }
    async fn requests(&self, id: Uuid) -> AppResult<Vec<FriendRequest>> {
        Err(DomainError::Unavailable)
    }
    async fn send_request(&self, id: Uuid, friend: Uuid) -> AppResult<()> {
        Err(DomainError::Unavailable)
    }
    async fn respond(&self, id: Uuid, request: Uuid, action: FriendAction) -> AppResult<()> {
        Err(DomainError::Unavailable)
    }
}
#[async_trait::async_trait]
impl DebtRepository for Memory {
    async fn create_debt(&self, id: Uuid, c: CreateDebt) -> AppResult<Debt> {
        Err(DomainError::Unavailable)
    }
    async fn finish_debt(&self, id: Uuid, debt: Uuid) -> AppResult<Debt> {
        Err(DomainError::Unavailable)
    }
    async fn list_debts(&self, id: Uuid, owed: bool) -> AppResult<Vec<Debt>> {
        Err(DomainError::Unavailable)
    }
}
#[async_trait::async_trait]
impl DiscordRepository for Memory {
    async fn generate_code(&self, id: Uuid) -> AppResult<DiscordVerification> {
        Err(DomainError::Unavailable)
    }
    async fn verify_code(&self, code: String, discord_id: String, name: String) -> AppResult<()> {
        Err(DomainError::Unavailable)
    }
    async fn discord_status(&self, id: Uuid) -> AppResult<DiscordStatus> {
        Err(DomainError::Unavailable)
    }
    async fn disconnect(&self, id: Uuid) -> AppResult<()> {
        Err(DomainError::Unavailable)
    }
    async fn set_notification(
        &self,
        id: Uuid,
        kind: NotificationKind,
        enabled: bool,
    ) -> AppResult<()> {
        Err(DomainError::Unavailable)
    }
}
#[async_trait::async_trait]
impl Health for Memory {
    async fn ready(&self) -> AppResult<()> {
        Ok(())
    }
}
async fn app() -> furnace_rs::axum::Router {
    let secret = "test-only-secret-32-characters-long";
    let model = Arc::new(
        NativeClassifier::load(
            &PathBuf::from(env!("CARGO_MANIFEST_DIR"))
                .join("../../../models/transaction-model.json"),
        )
        .unwrap(),
    );
    let services = Arc::new(Services::new(
        Arc::new(Memory {
            sessions: Mutex::new(HashMap::new()),
        }),
        model,
        Arc::new(Tokens::new(secret.into()).unwrap()),
    ));
    let config = ConfigBuilder::new()
        .source(
            furnace_rs::core::MapSource::new(
                "test",
                [
                    ("passport.secret", secret),
                    ("tracker.public_origin", "http://localhost:8080"),
                    ("tracker.model_path", "/unused-test-model.json"),
                    (
                        "persistence.seaorm.url",
                        "postgresql://tracker:password@localhost/tracker_test",
                    ),
                    ("server.cors.credentials", "true"),
                ],
            )
            .with_string_array("server.cors.origins", ["http://localhost:8080"])
            .with_string_array(
                "server.cors.methods",
                ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            )
            .with_string_array("server.cors.allowed_headers", ["content-type"]),
        )
        .build()
        .unwrap();
    let mut builder = Furnace::builder_with_config(config);
    builder.root::<TrackerCauldron>().unwrap();
    let pool = sqlx::postgres::PgPoolOptions::new()
        .connect_lazy("postgresql://tracker:password@localhost/tracker_test")
        .unwrap();
    builder
        .provide(sea_orm::SqlxPostgresConnector::from_sqlx_postgres_pool(
            pool.clone(),
        ))
        .unwrap();
    builder.provide(services.classifier.clone()).unwrap();
    builder.provide(services.tokens.clone()).unwrap();
    builder.provide(services).unwrap();
    let application = builder.build().await.unwrap();
    configure_router(&application, build_router(&application).unwrap()).unwrap()
}
#[tokio::test]
async fn all_protected_routes_require_session() {
    let router = app().await;
    for (method, path) in [
        ("GET", "/user/profile"),
        ("GET", "/user/records"),
        ("POST", "/user/record"),
        ("PUT", "/user/record/commit"),
        (
            "DELETE",
            "/user/record/00000000-0000-0000-0000-000000000001",
        ),
        ("GET", "/debt"),
        ("GET", "/debt/owed"),
        ("POST", "/debt/create"),
        ("PUT", "/debt/finish"),
        ("GET", "/user/friend"),
        ("POST", "/user/friend/search"),
        ("POST", "/user/friend/add"),
        ("GET", "/user/friend/request"),
        ("PUT", "/user/friend/request/response"),
        ("POST", "/user/discord/verify"),
        ("GET", "/user/discord/status"),
        ("DELETE", "/user/discord"),
        ("PUT", "/user/discord/notification"),
    ] {
        let response = router
            .clone()
            .oneshot(
                Request::builder()
                    .method(method)
                    .uri(path)
                    .header("content-type", "application/json")
                    .body(Body::from("{}"))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(
            response.status(),
            StatusCode::UNAUTHORIZED,
            "{method} {path}"
        );
    }
}
#[tokio::test]
async fn login_cookie_flags_profile_and_logout_revocation() {
    let router = app().await;
    let req = Request::builder()
        .method("POST")
        .uri("/auth/login")
        .header("content-type", "application/json")
        .body(Body::from(
            r#"{"username":"tester","password":"password123"}"#,
        ))
        .unwrap();
    let response = router.clone().oneshot(req).await.unwrap();
    assert_eq!(response.status(), StatusCode::OK);
    let cookies = response
        .headers()
        .get_all("set-cookie")
        .iter()
        .map(|v| v.to_str().unwrap().to_string())
        .collect::<Vec<_>>();
    assert_eq!(cookies.len(), 2);
    assert!(
        cookies
            .iter()
            .all(|c| c.contains("HttpOnly") && c.contains("SameSite=Lax"))
    );
    let cookie = cookies
        .iter()
        .map(|c| c.split(';').next().unwrap())
        .collect::<Vec<_>>()
        .join("; ");
    let body = to_bytes(response.into_body(), 100000).await.unwrap();
    let json: serde_json::Value = serde_json::from_slice(&body).unwrap();
    assert!(json["data"].get("password").is_none());
    let req = Request::builder()
        .uri("/user/profile")
        .header("cookie", &cookie)
        .body(Body::empty())
        .unwrap();
    assert_eq!(
        router.clone().oneshot(req).await.unwrap().status(),
        StatusCode::OK
    );
    let req = Request::builder()
        .method("POST")
        .uri("/auth/logout")
        .header("cookie", &cookie)
        .body(Body::empty())
        .unwrap();
    assert_eq!(
        router.clone().oneshot(req).await.unwrap().status(),
        StatusCode::OK
    );
    let req = Request::builder()
        .uri("/auth/validate-session")
        .header("cookie", &cookie)
        .body(Body::empty())
        .unwrap();
    assert_eq!(
        router.oneshot(req).await.unwrap().status(),
        StatusCode::UNAUTHORIZED
    );
}
#[tokio::test]
async fn cross_origin_mutation_rejected_and_bad_json_is_native_validation_error() {
    let router = app().await;
    let r = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/auth/login")
                .header("origin", "https://attacker.example")
                .header("content-type", "application/json")
                .body(Body::from("{}"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(r.status(), StatusCode::FORBIDDEN);
    let r = router
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/auth/login")
                .header("content-type", "application/json")
                .body(Body::from("not json"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(r.status(), StatusCode::UNPROCESSABLE_ENTITY);
}

#[tokio::test]
async fn native_input_validation_aggregates_issues_before_creating_a_user() {
    let response = app()
        .await
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/user/register")
                .header("content-type", "application/json")
                .body(Body::from(r#"{"username":"x","password":"secret!"}"#))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let body = to_bytes(response.into_body(), 100000).await.unwrap();
    let body: serde_json::Value = serde_json::from_slice(&body).unwrap();
    assert_eq!(body["error"]["code"], "validation_error");
    let issues = body["error"]["issues"].as_array().unwrap();
    assert!(
        issues
            .iter()
            .any(|i| i["source"] == "body" && i["path"] == serde_json::json!(["username"]))
    );
    assert!(
        issues
            .iter()
            .any(|i| i["source"] == "body" && i["path"] == serde_json::json!(["password"]))
    );
    assert!(!body.to_string().contains("secret!"));
}

#[tokio::test]
async fn configured_native_cors_allows_credentialed_preflight_only_for_tracker() {
    let router = app().await;
    for (origin, allowed) in [
        ("http://localhost:8080", true),
        ("https://attacker.example", false),
    ] {
        let response = router
            .clone()
            .oneshot(
                Request::builder()
                    .method("OPTIONS")
                    .uri("/user/record")
                    .header("origin", origin)
                    .header("access-control-request-method", "POST")
                    .header("access-control-request-headers", "content-type")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(
            response
                .headers()
                .contains_key("access-control-allow-origin"),
            allowed
        );
        if allowed {
            assert_eq!(response.headers()["access-control-allow-origin"], origin);
            assert_eq!(
                response.headers()["access-control-allow-credentials"],
                "true"
            );
        }
    }
}

#[tokio::test]
async fn authenticated_mutations_use_native_origin_predicate_and_input_validation() {
    let router = app().await;
    let login = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/auth/login")
                .header("content-type", "application/json")
                .body(Body::from(
                    r#"{"username":"tester","password":"password123"}"#,
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    let cookie = login
        .headers()
        .get_all("set-cookie")
        .iter()
        .map(|h| h.to_str().unwrap().split(';').next().unwrap())
        .collect::<Vec<_>>()
        .join("; ");
    for (method, path) in [
        ("POST", "/user/record"),
        ("PUT", "/user/profile"),
        ("PUT", "/user/record/commit"),
        ("POST", "/user/friend/add"),
        ("POST", "/debt/create"),
        ("PUT", "/debt/finish"),
        ("DELETE", "/user/discord"),
        ("PUT", "/user/discord/notification"),
    ] {
        let response = router
            .clone()
            .oneshot(
                Request::builder()
                    .method(method)
                    .uri(path)
                    .header("cookie", &cookie)
                    .header("origin", "https://attacker.example")
                    .header("content-type", "application/json")
                    .body(Body::from("{}"))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::FORBIDDEN, "{method} {path}");
    }
    let response = router
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/user/record")
                .header("cookie", cookie)
                .header("content-type", "application/json")
                .body(Body::from(
                    r#"{"title":" ","amount":-1,"date":"2026-10-08"}"#,
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let body = to_bytes(response.into_body(), 100000).await.unwrap();
    let body: serde_json::Value = serde_json::from_slice(&body).unwrap();
    let issues = body["error"]["issues"].as_array().unwrap();
    assert!(
        issues
            .iter()
            .any(|i| i["path"] == serde_json::json!(["title"]))
    );
    assert!(
        issues
            .iter()
            .any(|i| i["path"] == serde_json::json!(["amount"]))
    );
}

#[tokio::test]
async fn refresh_renews_access_cookie_and_revoked_sessions_cannot_refresh() {
    let router = app().await;
    let response = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/auth/login")
                .header("content-type", "application/json")
                .body(Body::from(
                    r#"{"username":"tester","password":"password123"}"#,
                ))
                .unwrap(),
        )
        .await
        .unwrap();
    let refresh = response
        .headers()
        .get_all("set-cookie")
        .iter()
        .map(|h| h.to_str().unwrap().split(';').next().unwrap())
        .find(|c| c.starts_with("refresh_token="))
        .unwrap()
        .to_owned();
    let request = || {
        Request::builder()
            .method("POST")
            .uri("/auth/refresh")
            .header("cookie", &refresh)
            .body(Body::empty())
            .unwrap()
    };
    let renewed = router.clone().oneshot(request()).await.unwrap();
    assert_eq!(renewed.status(), StatusCode::OK);
    let access = renewed
        .headers()
        .get_all("set-cookie")
        .iter()
        .map(|h| h.to_str().unwrap().split(';').next().unwrap())
        .find(|c| c.starts_with("token="))
        .unwrap()
        .to_owned();
    let response = router
        .clone()
        .oneshot(
            Request::builder()
                .uri("/user/profile")
                .header("cookie", access)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::OK);
    let response = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/auth/logout")
                .header("cookie", &refresh)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::OK);
    assert_eq!(
        router.oneshot(request()).await.unwrap().status(),
        StatusCode::UNAUTHORIZED
    );
}

#[tokio::test]
async fn refresh_rejects_cross_origin_and_access_token_substitution() {
    let router = app().await;
    let response = router
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/auth/refresh")
                .header("origin", "https://attacker.example")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::FORBIDDEN);
    let codec = Tokens::new("test-only-secret-32-characters-long".into()).unwrap();
    let pair = codec.issue(Uuid::new_v4(), Uuid::new_v4()).unwrap();
    let response = router
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/auth/refresh")
                .header("cookie", format!("refresh_token={}", pair.access))
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}
