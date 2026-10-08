//! In-process inference for the portable, trained TF-IDF/logistic model.
use serde::Deserialize;
use std::{
    collections::{HashMap, HashSet},
    path::Path,
};
use tracker_application::{AppResult, Classification, Classifier, DomainError};

#[derive(Deserialize)]
struct Vectorizer {
    vocabulary: HashMap<String, usize>,
    idf: Vec<f64>,
    ngram_range: [usize; 2],
    sublinear_tf: bool,
    norm: String,
}
#[derive(Deserialize)]
struct Linear {
    classes: Vec<String>,
    coefficients: Vec<Vec<f64>>,
    intercepts: Vec<f64>,
}
#[derive(Deserialize)]
struct Preprocessing {
    stopwords: HashSet<String>,
}
#[derive(Deserialize)]
struct MoneyFeatures {
    in_cues: Vec<String>,
    out_cues: Vec<String>,
    feature_count: usize,
}
#[derive(Deserialize)]
struct Artifact {
    format_version: u32,
    preprocessing: Preprocessing,
    word: Vectorizer,
    char: Vectorizer,
    money: MoneyFeatures,
    primary: Linear,
    secondary: Linear,
    income_categories: HashSet<String>,
    secondary_categories: HashMap<String, HashSet<String>>,
}
pub struct NativeClassifier {
    artifact: Artifact,
}
impl NativeClassifier {
    pub fn load_verified(path: &Path) -> AppResult<Self> {
        use sha2::{Digest, Sha256};
        let manifest_path = path
            .parent()
            .ok_or(DomainError::Unavailable)?
            .join("manifest.json");
        let manifest: serde_json::Value = serde_json::from_slice(
            &std::fs::read(manifest_path).map_err(|_| DomainError::Unavailable)?,
        )
        .map_err(|_| DomainError::Unavailable)?;
        let actual = format!(
            "{:x}",
            Sha256::digest(std::fs::read(path).map_err(|_| DomainError::Unavailable)?)
        );
        if manifest["sha256"].as_str() != Some(actual.as_str()) {
            return Err(DomainError::Unavailable);
        }
        Self::load(path)
    }

    pub fn load(path: &Path) -> AppResult<Self> {
        let bytes = std::fs::read(path).map_err(|_| DomainError::Unavailable)?;
        let a: Artifact = serde_json::from_slice(&bytes).map_err(|_| DomainError::Unavailable)?;
        if a.format_version != 1
            || a.money.feature_count != 8
            || a.word.ngram_range != [1, 2]
            || a.char.ngram_range != [3, 5]
        {
            return Err(DomainError::Unavailable);
        }
        for v in [&a.word, &a.char] {
            let ids: HashSet<usize> = v.vocabulary.values().copied().collect();
            if ids.len() != v.idf.len()
                || !ids.iter().all(|i| *i < v.idf.len())
                || v.norm != "l2"
                || !v.sublinear_tf
                || !v.idf.iter().all(|x| x.is_finite() && *x > 0.0)
            {
                return Err(DomainError::Unavailable);
            }
        }
        let count = a.word.idf.len() + a.char.idf.len() + 8;
        for l in [&a.primary, &a.secondary] {
            if l.classes.len() < 2
                || l.classes.len() != l.coefficients.len()
                || l.classes.len() != l.intercepts.len()
                || l.classes.iter().collect::<HashSet<_>>().len() != l.classes.len()
                || !l.intercepts.iter().all(|x| x.is_finite())
                || !l
                    .coefficients
                    .iter()
                    .all(|r| r.len() == count && r.iter().all(|x| x.is_finite()))
            {
                return Err(DomainError::Unavailable);
            }
        }
        if !a
            .primary
            .classes
            .iter()
            .all(|c| a.secondary_categories.contains_key(c))
        {
            return Err(DomainError::Unavailable);
        }
        Ok(Self { artifact: a })
    }
    fn features(&self, title: &str) -> Vec<(usize, f64)> {
        let cleaned: String = title
            .to_lowercase()
            .chars()
            .map(|c| {
                if c.is_ascii_lowercase() || c.is_ascii_digit() || c.is_whitespace() {
                    c
                } else {
                    ' '
                }
            })
            .collect();
        let words: Vec<&str> = cleaned
            .split_whitespace()
            .filter(|t| t.len() > 1 && !self.artifact.preprocessing.stopwords.contains(*t))
            .collect();
        let text = words.join(" ");
        let mut wordgrams: Vec<String> = words.iter().map(|s| s.to_string()).collect();
        wordgrams.extend(words.windows(2).map(|w| format!("{} {}", w[0], w[1])));
        let mut chars = Vec::new();
        for word in &words {
            let w = format!(" {word} ");
            for n in 3..=5 {
                if w.len() <= n {
                    chars.push(w.clone());
                    break;
                }
                for i in 0..=w.len() - n {
                    chars.push(w[i..i + n].to_string());
                }
            }
        }
        let mut f = tfidf(&self.artifact.word, wordgrams, 0);
        f.extend(tfidf(
            &self.artifact.char,
            chars,
            self.artifact.word.idf.len(),
        ));
        let low = format!(" {text} ");
        let m = &self.artifact.money;
        let cue = |c: &String| {
            if c.starts_with(' ') || c.ends_with(' ') || c.contains(' ') {
                low.contains(c)
            } else {
                low.contains(&format!(" {c} "))
            }
        };
        let numbers = [
            m.in_cues.iter().filter(|c| cue(c)).count() as f64,
            m.out_cues.iter().filter(|c| cue(c)).count() as f64,
            f64::from(m.in_cues.iter().any(|c| text.starts_with(c))),
            f64::from(m.out_cues.iter().any(|c| text.starts_with(c))),
            f64::from(words.contains(&"ke")),
            f64::from(words.contains(&"dari")),
            f64::from(words.contains(&"sama")),
            words.len() as f64,
        ];
        let offset = self.artifact.word.idf.len() + self.artifact.char.idf.len();
        f.extend(
            numbers
                .into_iter()
                .enumerate()
                .filter(|(_, x)| *x != 0.0)
                .map(|(i, x)| (offset + i, x)),
        );
        f
    }
}
fn tfidf(v: &Vectorizer, grams: Vec<String>, offset: usize) -> Vec<(usize, f64)> {
    let mut counts: HashMap<usize, usize> = HashMap::new();
    for g in grams {
        if let Some(i) = v.vocabulary.get(&g) {
            *counts.entry(*i).or_default() += 1;
        }
    }
    let mut x: Vec<(usize, f64)> = counts
        .into_iter()
        .map(|(i, n)| (i, (1.0 + (n as f64).ln()) * v.idf[i]))
        .collect();
    let norm = x.iter().map(|(_, x)| x * x).sum::<f64>().sqrt();
    if norm > 0.0 {
        for (i, n) in &mut x {
            *i += offset;
            *n /= norm;
        }
    }
    x.sort_unstable_by_key(|(i, _)| *i);
    x
}
fn probabilities(l: &Linear, f: &[(usize, f64)]) -> Vec<f64> {
    let mut logits: Vec<f64> = l
        .coefficients
        .iter()
        .zip(&l.intercepts)
        .map(|(row, b)| b + f.iter().map(|(i, v)| row[*i] * v).sum::<f64>())
        .collect();
    let max = logits.iter().copied().fold(f64::NEG_INFINITY, f64::max);
    for x in &mut logits {
        *x = (*x - max).exp();
    }
    let total: f64 = logits.iter().sum();
    for x in &mut logits {
        *x /= total;
    }
    logits
}
fn best(p: &[f64]) -> usize {
    p.iter()
        .enumerate()
        .max_by(|a, b| a.1.total_cmp(b.1))
        .map(|(i, _)| i)
        .unwrap_or(0)
}
impl Classifier for NativeClassifier {
    fn classify(&self, title: &str) -> AppResult<Classification> {
        if title.chars().count() > 200 {
            return Err(DomainError::Validation(
                "Title exceeds 200 characters".into(),
            ));
        }
        let f = self.features(title);
        let a = &self.artifact;
        let p = probabilities(&a.primary, &f);
        let s = probabilities(&a.secondary, &f);
        let category = a.primary.classes[best(&p)].clone();
        let secondary_category = a.secondary.classes[best(&s)].clone();
        let kind = if a.income_categories.contains(&category) {
            "income"
        } else {
            "expense"
        }
        .into();
        Ok(Classification {
            category,
            secondary_category,
            kind,
            primary_probabilities: p,
            secondary_probabilities: s,
        })
    }
    fn validate_categories(&self, primary: &str, secondary: &str) -> AppResult<()> {
        if self
            .artifact
            .secondary_categories
            .get(primary)
            .is_some_and(|s| s.contains(secondary))
        {
            Ok(())
        } else {
            Err(DomainError::Validation(
                "Invalid primary/secondary category pair".into(),
            ))
        }
    }
}
