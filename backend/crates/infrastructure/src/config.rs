use furnace_rs::prelude::*;
use std::path::PathBuf;
use tracker_application::DomainError;

#[derive(Clone, Configuration)]
#[config(prefix = "tracker")]
pub struct TrackerSettings {
    pub public_origin: String,
    #[config(default = false)]
    pub cookie_secure: bool,
    pub model_path: PathBuf,
    pub discord: DiscordSettings,
}

#[derive(Clone, Configuration)]
#[config(prefix = "")]
pub struct DiscordSettings {
    pub bot_token: Option<Secret<String>>,
    pub client_id: Option<String>,
    pub public_key: Option<String>,
    #[config(default = "Tracker")]
    pub bot_username: String,
}

impl TrackerSettings {
    pub fn discord(&self) -> furnace_rs::core::Result<Option<crate::discord::DiscordConfig>> {
        crate::discord::DiscordConfig::from_values(
            self.discord
                .bot_token
                .as_ref()
                .map(|t| t.expose().clone())
                .unwrap_or_default(),
            self.discord.client_id.clone().unwrap_or_default(),
            self.discord.public_key.clone().unwrap_or_default(),
            self.discord.bot_username.clone(),
        )
        .map_err(framework_error)
    }
}
impl Injector for TrackerSettings {
    type Dependencies = (Config,);
    async fn inject((config,): Self::Dependencies) -> furnace_rs::core::Result<Self> {
        let settings: Self = config.parse()?;
        let uri = settings
            .public_origin
            .parse::<furnace_rs::axum::http::Uri>()
            .map_err(|_| invalid_origin())?;
        if !matches!(uri.scheme_str(), Some("http" | "https"))
            || uri.authority().is_none()
            || settings.public_origin.ends_with('/')
            || settings.public_origin.contains(['@', '#', '?'])
            || uri.path() != "/"
        {
            return Err(invalid_origin());
        }
        settings.discord()?;
        Ok(settings)
    }
}
fn invalid_origin() -> furnace_rs::core::Error {
    furnace_rs::core::ConfigurationErrors::from_issue(furnace_rs::core::ConfigurationIssue::new(
        "tracker.public_origin",
        "invalid_origin",
        "must be an exact HTTP origin without a path",
    ))
    .into()
}
pub(crate) fn framework_error(_: DomainError) -> furnace_rs::core::Error {
    furnace_rs::core::Error::new(Diagnostic::new(
        furnace_rs::core::DiagnosticCode::new("TRACKER001"),
        "Tracker resource initialization failed",
        "Check application configuration and resource availability",
    ))
}

#[cauldron]
pub struct ConfigurationCauldron;
impl Cauldron for ConfigurationCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.provide::<TrackerSettings>()
            .export::<TrackerSettings>()
            .global()
    }
}
