use ed25519_dalek::{Signer, SigningKey};
use tracker_infrastructure::discord::{is_weekly_window, verify_signature};
#[test]
fn verifies_signed_body_and_rejects_forgery_and_replay() {
    let key = SigningKey::from_bytes(&[7; 32]);
    let body = br#"{"type":1}"#;
    let now = chrono::Utc::now().timestamp();
    let timestamp = now.to_string();
    let mut message = timestamp.as_bytes().to_vec();
    message.extend(body);
    let signature = key.sign(&message);
    let hex = |b: &[u8]| b.iter().map(|v| format!("{v:02x}")).collect::<String>();
    let public = hex(key.verifying_key().as_bytes());
    let sig = hex(&signature.to_bytes());
    assert!(verify_signature(&public, &sig, &timestamp, body, now).is_ok());
    assert!(verify_signature(&public, &sig, &timestamp, b"forged", now).is_err());
    assert!(verify_signature(&public, &sig, &timestamp, body, now + 301).is_err());
}
#[test]
fn weekly_window_is_saturday_20_wib() {
    assert!(is_weekly_window(
        chrono::DateTime::parse_from_rfc3339("2026-10-10T13:02:00Z")
            .unwrap()
            .to_utc()
    ));
    assert!(!is_weekly_window(
        chrono::DateTime::parse_from_rfc3339("2026-10-10T13:05:00Z")
            .unwrap()
            .to_utc()
    ));
}

#[test]
fn weekly_report_window_matches_sunday_to_saturday_wib() {
    let now = chrono::DateTime::parse_from_rfc3339("2026-10-10T13:02:00Z")
        .unwrap()
        .to_utc();
    let (start, end) = tracker_infrastructure::discord::report_window(now);
    assert_eq!(start.to_rfc3339(), "2026-10-03T17:00:00+00:00");
    assert_eq!(end.to_rfc3339(), "2026-10-10T13:00:00+00:00");
}

#[test]
fn weekly_report_includes_net_and_top_three_expense_categories() {
    use rust_decimal::Decimal;
    use tracker_infrastructure::discord::{WeeklyReport, format_weekly_report, report_window};
    let now = chrono::DateTime::parse_from_rfc3339("2026-10-10T13:02:00Z")
        .unwrap()
        .to_utc();
    let (start, end) = report_window(now);
    let report = WeeklyReport {
        start,
        end,
        income: Decimal::from(1000),
        expense: Decimal::from(300),
        top_categories: vec![
            ("makanan".into(), Decimal::from(200)),
            ("transport".into(), Decimal::from(100)),
        ],
    };
    let body = format_weekly_report(&report);
    assert!(body.contains("Net minggu ini: 700"));
    assert!(body.contains("makanan — 200"));
    assert!(body.contains("transport — 100"));
    assert!(body.contains("2026-10-04") && body.contains("2026-10-10"));
}
