use furnace_rs::prelude::*;
use tracker_http::TrackerCauldron;

#[cauldron]
struct AppCauldron;
impl Cauldron for AppCauldron {
    fn register(self) -> CauldronRegistration<Self> {
        self.import(LoggerCauldron).import(TrackerCauldron)
    }
}

#[furnace_rs::main]
async fn main() -> Result<(), HttpRuntimeError> {
    Furnace::burn::<AppCauldron>().await
}
