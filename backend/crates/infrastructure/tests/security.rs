use tracker_application::TokenCodec;
use tracker_infrastructure::security::{Passwords, Tokens};
#[test]
fn bcrypt_roundtrip_and_wrong_password() {
    let hash = Passwords::hash("password123").unwrap();
    assert!(hash.starts_with("$2b$12$"));
    assert!(Passwords::verify("password123", &hash).unwrap());
    assert!(!Passwords::verify("wrongpassword", &hash).unwrap());
}
#[test]
fn access_and_refresh_are_not_interchangeable() {
    let codec = Tokens::new("12345678901234567890123456789012".into()).unwrap();
    let user = uuid::Uuid::new_v4();
    let session = uuid::Uuid::new_v4();
    let pair = codec.issue(user, session).unwrap();
    assert_eq!(codec.verify_access(&pair.access).unwrap().user_id, user);
    assert!(codec.verify_access(&pair.refresh).is_err());
    assert!(codec.verify_refresh(&pair.access).is_err());
    assert!(codec.verify_refresh(&format!("{}x", pair.refresh)).is_err());
    assert!(Tokens::new("short".into()).is_err());
}
