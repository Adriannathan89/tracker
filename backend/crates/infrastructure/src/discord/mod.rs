//! Discord uses signed interactions and REST; no separate bot service is needed.
mod scheduler;
use crate::postgres::PgStore;
use chrono::{DateTime, Datelike, Timelike, Utc};
use ed25519_dalek::{Signature, VerifyingKey};
pub use scheduler::enqueue_weekly_report;
use tokio::{sync::watch, task::JoinHandle};
use tracker_application::{AppResult, DomainError};
#[derive(Clone)]
pub struct DiscordConfig {
    pub token: String,
    pub application_id: String,
    pub public_key: String,
    pub username: String,
}
impl DiscordConfig {
    pub fn from_values(
        token: String,
        application_id: String,
        public_key: String,
        username: String,
    ) -> AppResult<Option<Self>> {
        if token.is_empty() {
            return Ok(None);
        }
        if application_id.is_empty()
            || !application_id.bytes().all(|b| b.is_ascii_digit())
            || decode_hex(&public_key).is_none_or(|v| v.len() != 32)
        {
            return Err(DomainError::Validation(
                "Discord client ID and public key are required when enabled".into(),
            ));
        }
        Ok(Some(Self {
            token,
            application_id,
            public_key,
            username,
        }))
    }
}
fn decode_hex(s: &str) -> Option<Vec<u8>> {
    if !s.is_ascii() || !s.len().is_multiple_of(2) {
        return None;
    }
    (0..s.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&s[i..i + 2], 16).ok())
        .collect()
}
pub fn verify_signature(
    key: &str,
    signature: &str,
    timestamp: &str,
    body: &[u8],
    now: i64,
) -> AppResult<()> {
    let t = timestamp
        .parse::<i64>()
        .map_err(|_| DomainError::Unauthorized)?;
    if now.abs_diff(t) > 300 {
        return Err(DomainError::Unauthorized);
    }
    let key: [u8; 32] = decode_hex(key)
        .and_then(|v| v.try_into().ok())
        .ok_or(DomainError::Unauthorized)?;
    let signature = decode_hex(signature)
        .and_then(|v| Signature::from_slice(&v).ok())
        .ok_or(DomainError::Unauthorized)?;
    let key = VerifyingKey::from_bytes(&key).map_err(|_| DomainError::Unauthorized)?;
    let mut msg = timestamp.as_bytes().to_vec();
    msg.extend(body);
    key.verify_strict(&msg, &signature)
        .map_err(|_| DomainError::Unauthorized)
}
pub fn is_weekly_window(now: DateTime<Utc>) -> bool {
    let local = now + chrono::Duration::hours(7);
    local.weekday() == chrono::Weekday::Sat && local.hour() == 20 && local.minute() < 5
}
/// Fixed reference reporting week: Sunday 00:00 WIB through Saturday 20:00 WIB.
pub fn report_window(now: DateTime<Utc>) -> (DateTime<Utc>, DateTime<Utc>) {
    let local = now + chrono::Duration::hours(7);
    let sunday = local
        .date_naive()
        .and_hms_opt(0, 0, 0)
        .expect("midnight is valid")
        - chrono::Duration::days(local.weekday().num_days_from_sunday().into());
    let start = sunday.and_utc() - chrono::Duration::hours(7);
    (
        start,
        start + chrono::Duration::days(6) + chrono::Duration::hours(20),
    )
}
pub struct WeeklyReport {
    pub start: DateTime<Utc>,
    pub end: DateTime<Utc>,
    pub income: rust_decimal::Decimal,
    pub expense: rust_decimal::Decimal,
    pub top_categories: Vec<(String, rust_decimal::Decimal)>,
}
pub fn format_weekly_report(report: &WeeklyReport) -> String {
    let start = (report.start + chrono::Duration::hours(7)).format("%Y-%m-%d");
    let end =
        (report.end + chrono::Duration::hours(7) - chrono::Duration::seconds(1)).format("%Y-%m-%d");
    let mut body = format!(
        "Laporan mingguan Tracker — {start} – {end}\nPemasukan: {}\nPengeluaran: {}\nNet minggu ini: {}",
        report.income,
        report.expense,
        report.income - report.expense
    );
    if !report.top_categories.is_empty() {
        body.push_str("\nTop kategori pengeluaran:");
        for (name, total) in report.top_categories.iter().take(3) {
            body.push_str(&format!("\n{name} — {total}"));
        }
    }
    if report.income.is_zero() && report.expense.is_zero() {
        body.push_str("\nBelum ada transaksi minggu ini.");
    }
    body
}
pub struct DiscordRuntime {
    stop: watch::Sender<bool>,
    worker: JoinHandle<()>,
}
impl DiscordRuntime {
    pub fn start(config: DiscordConfig, store: PgStore) -> AppResult<Self> {
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(10))
            .user_agent("Tracker/0.1")
            .build()
            .map_err(|_| DomainError::Unavailable)?;
        let (stop, mut stopping) = watch::channel(false);
        let worker = tokio::spawn(async move {
            let registration=client.post(format!("https://discord.com/api/v10/applications/{}/commands",config.application_id)).header("Authorization",format!("Bot {}",config.token)).json(&serde_json::json!({"name":"verify","description":"Hubungkan akun Discord dengan Tracker","integration_types":[0,1],"contexts":[0,1,2],"options":[{"name":"code","description":"Kode 6 digit dari profil Tracker","type":3,"required":true,"min_length":6,"max_length":6}]})).send().await;
            match registration {
                Ok(r) if r.status().is_success() => {}
                _ => eprintln!(
                    "Discord command registration failed; core application remains available"
                ),
            }
            let mut tick = tokio::time::interval(std::time::Duration::from_secs(15));
            loop {
                tokio::select! {
                 _=stopping.changed()=>break,
                 _=tick.tick()=>{
                  if let Err(e)=scheduler::run_once(&store,&config,&client).await{eprintln!("Discord background task: {e}");}
                 }
                }
            }
        });
        Ok(Self { stop, worker })
    }
    pub async fn shutdown(self) {
        let _ = self.stop.send(true);
        let mut worker = self.worker;
        if tokio::time::timeout(std::time::Duration::from_secs(15), &mut worker)
            .await
            .is_err()
        {
            worker.abort();
            let _ = worker.await;
        }
    }
}
