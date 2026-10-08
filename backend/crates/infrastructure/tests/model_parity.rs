use serde::Deserialize;
use std::path::PathBuf;
use tracker_application::Classifier;
use tracker_infrastructure::model::NativeClassifier;
#[derive(Deserialize)]
struct Fixture {
    title: String,
    category: String,
    secondary_category: String,
    primary_probabilities: Vec<f64>,
    secondary_probabilities: Vec<f64>,
}
fn root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../..")
}
#[test]
fn parity_matches_python_including_empty_processed_titles() {
    let m = NativeClassifier::load(&root().join("../models/transaction-model.json")).unwrap();
    let fixtures: Vec<Fixture> = serde_json::from_slice(
        &std::fs::read(root().join("crates/infrastructure/tests/fixtures/model-parity.json"))
            .unwrap(),
    )
    .unwrap();
    assert!(fixtures.len() > 200);
    for f in fixtures {
        let result = m.classify(&f.title).unwrap();
        assert_eq!(result.category, f.category, "{}", f.title);
        assert_eq!(
            result.secondary_category, f.secondary_category,
            "{}",
            f.title
        );
        for (a, b) in result
            .primary_probabilities
            .iter()
            .zip(f.primary_probabilities.iter())
            .chain(
                result
                    .secondary_probabilities
                    .iter()
                    .zip(f.secondary_probabilities.iter()),
            )
        {
            assert!((a - b).abs() <= 1e-6, "{}: {a} versus {b}", f.title);
        }
    }
}
#[test]
fn rejects_unknown_artifact_version() {
    let p = std::env::temp_dir().join(format!("tracker-model-{}.json", uuid::Uuid::new_v4()));
    std::fs::write(&p, r#"{"format_version":999}"#).unwrap();
    assert!(NativeClassifier::load(&p).is_err());
    std::fs::remove_file(p).unwrap();
}
#[test]
fn checksum_rejects_tampered_model() {
    let dir = std::env::temp_dir().join(format!("tracker-checksum-{}", uuid::Uuid::new_v4()));
    std::fs::create_dir(&dir).unwrap();
    std::fs::write(dir.join("transaction-model.json"), b"tampered").unwrap();
    std::fs::write(dir.join("manifest.json"), r#"{"sha256":"incorrect"}"#).unwrap();
    assert!(NativeClassifier::load_verified(&dir.join("transaction-model.json")).is_err());
    std::fs::remove_dir_all(dir).unwrap();
}

#[test]
fn rejects_invalid_dimensions() {
    let original = root().join("../models/transaction-model.json");
    let mut artifact: serde_json::Value =
        serde_json::from_slice(&std::fs::read(original).unwrap()).unwrap();
    artifact["primary"]["coefficients"][0]
        .as_array_mut()
        .unwrap()
        .pop();
    let path =
        std::env::temp_dir().join(format!("tracker-dimensions-{}.json", uuid::Uuid::new_v4()));
    std::fs::write(&path, serde_json::to_vec(&artifact).unwrap()).unwrap();
    assert!(NativeClassifier::load(&path).is_err());
    std::fs::remove_file(path).unwrap();
}
