# Tracker Monorepo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the existing application as Tracker with an Angular frontend, a Furnace Rust backend, in-process trained classification, and a complete Docker Compose deployment.

**Architecture:** Four backend library crates enforce inward dependencies: domain, application, infrastructure, and HTTP. A Furnace composition root connects use cases to PostgreSQL, native model inference, and optional Discord adapters. Python trains and exports the model offline.

**Tech Stack:** Angular 21, TypeScript, Tailwind, Angular Material, npm; Rust, furnace-rs, SQLx/PostgreSQL, decimal arithmetic, bcrypt; Python/scikit-learn; Docker Compose and Nginx.

**Spec:** `docs/superpowers/specs/2026-10-08-tracker-monorepo-design.md` (approved).

## Global Constraints

- Confirmed database requirement: a fresh Tracker database with the existing app features preserved.
- `app/` contains the frontend; its package and Angular project names are `tracker`.
- Domain has no Furnace or SQL dependencies; application depends on domain and defines ports; infrastructure implements those ports; HTTP calls application use cases.
- Preserve request field names, response envelopes, and the frontend's camelCase JSON contract.
- Store money as fixed precision numeric values and use decimal arithmetic internally.
- Keep Python for offline model training and export only; inference runs inside the Rust backend.
- Do not replace trained predictions with keyword rules. Remove `SLM_URL` configuration.
- Rust must match Python labels and probabilities; initial absolute probability error target is <= 1e-6.
- The default Compose project name is `tracker`; three persistent services are frontend, backend, and PostgreSQL.
- Keep Discord optional and run it within the main backend process.
- Retain reference sources and existing `app/.git`; exclude secrets, nested reference Git metadata, dependency directories, virtual environments, and build outputs from copies/images.
- The root has no usable writable Git repository. Use file changes as checkpoints; do not manufacture successful commits or mutate mounted metadata.
- Network-blocked dependency/build checks must be reported accurately. A blocked check does not count as passing.

## Review Focus

- A title containing only stopwords or punctuation must produce the same model result as Python rather than divide by zero; Task 3.
- A secondary-only category correction must persist and be recorded as feedback; Task 5.
- Two browser requests committing one record simultaneously must change cash exactly once; Task 5.
- Renaming a user must not invalidate an otherwise valid session through a stale username claim; Task 4.
- Restarting during the weekly Discord window must not enqueue the same report twice; Task 8.

## File and interface conventions

Backend packages: `tracker-domain`, `tracker-application`, `tracker-infrastructure`, `tracker-http`, and executable `tracker-backend`. Shared IDs are `uuid::Uuid`; money is `rust_decimal::Decimal`; instants are UTC `chrono::DateTime<Utc>`; record dates are `chrono::NaiveDate`.

Domain files define `User`, `UserSummary`, `Record`, `Category`, `Debt`, `FriendRequest`, `Friend`, `Profile`, `Session`, `Classification`, and `DomainError`. Entities do not derive SQLx traits. Domain errors are `Validation`, `Unauthorized`, `Forbidden`, `NotFound`, `Conflict`, and `Unavailable`, with safe messages. `User` contains credential data only internally; HTTP serializes explicit public DTOs.

Application ports use async-trait for object-safe async calls. `AppResult<T> = Result<T, DomainError>`. Each use case has `new(...)` with `Arc<dyn Port>` dependencies. Infrastructure maps SQL/adapter errors to `DomainError`; it logs retained diagnostic causes without exposing them in HTTP.

Commands live in `backend/crates/application/src/commands.rs`: `Credentials { username, password }`, `CreateRecord { title, description, amount, date }`, `CommitRecord { record_id, category: Option<String>, secondary_category: Option<String> }`, `CreateDebt { amount, description, debtor_id }`, and `FriendAction::{Accept, Reject}`. HTTP DTOs map camelCase onto these commands.

## Task 1: Deliver the renamed Angular application

**Files:** Copy permitted files from `reference/bayarWoyFE/` into `app/`; modify `app/package.json`, `app/package-lock.json`, `app/angular.json`, `app/src/index.html`, `app/src/app/app.ts`, product labels/assets, and `app/scripts/generate-env.mjs`; create `app/proxy.conf.json`, `app/.env.example`.

**Interfaces:** Browser API base is `/api`; Angular dev proxy sends `/api/*` to `http://127.0.0.1:8080/*`. Production build outputs `app/dist/tracker/browser`.

- [ ] Copy source/configuration with explicit exclusions and preserve existing Git metadata.
- [ ] Rename package, Angular project/build targets, output path, visible brand labels, and wordmarks to Tracker. Edit existing SVG assets directly. Preserve Indonesian transaction wording and the current UI.
- [ ] Change environment generation to read `TRACKER_API_BASE_URL` with default `/api`, honor process environment before optional `.env`, and safely serialize generated TypeScript. Update Axios import/export names and development proxy.
- [ ] Run `cd app && npm ci && npm run build`; expect a successful Tracker production build. Inspect the built title and API configuration. Run any actual existing tests; do not introduce tests that merely assert renamed strings.
- [ ] Checkpoint the changed frontend files and record verification results.

## Task 2: Train and export the portable model

**Files:** Create `training/src/classifier.py`, `training/src/train.py`, `training/src/export.py`, `training/src/fixtures.py`, `training/requirements.txt`, `training/tests/test_export.py`, `training/data/transactions_v5_clean.csv`, `models/transaction-model.json`, `models/manifest.json`, and `backend/crates/infrastructure/tests/fixtures/model-parity.json`.

**Interfaces:** `export_model(model: TransactionModel, output: Path) -> dict` writes artifact format version `1`. Artifact keys: `format_version`, `preprocessing`, `word`, `char`, `money`, `primary`, `secondary`, `income_categories`, `secondary_categories`. Vectorizers include `vocabulary`, `idf`, `ngram_range`, `sublinear_tf`, `norm`; classifiers include `classes`, `coefficients`, `intercepts`. `generate_fixtures(model, titles: list[str], output: Path) -> None` writes unrounded primary/secondary probability vectors and labels. Manifest includes SHA-256, dataset hash, library versions, metrics, and training timestamp.

- [ ] Add `test_export_roundtrip` asserting coefficient dimensions, vocabulary index continuity, ordered labels, format version `1`, and finite numbers. Add fixture assertions for both direction contrasts from the reference.
- [ ] Run `python -m pytest training/tests/test_export.py`; expect failure before export exists.
- [ ] Adapt reference training/classifier code to the new paths and add CLI options for dataset, optional feedback CSV, output directory, and parity fixtures. Dependencies retain the reference scikit-learn `1.6.0` and NumPy `2.2.0`; omit FastAPI/Uvicorn. Train from the curated dataset rather than require joblib at runtime.
- [ ] Implement the exporter and fixture generator, including all eight direction features and preprocessing rules; no automatic serving or retraining loop.
- [ ] Run the tests and training/export commands. Expect a real trained artifact, five-fold primary/secondary metrics, manifest, and parity fixtures. Broader fixtures include a deterministic dataset sample plus contrasts, punctuation, repeated tokens, Unicode, unknown words, and inputs empty after preprocessing.
- [ ] Checkpoint training code and artifacts. Record actual metrics without inventing thresholds the spec does not require.

## Task 3: Establish backend boundaries and native inference

**Files:** Create `backend/Cargo.toml`, `backend/crates/{domain,application,infrastructure,http}/Cargo.toml`, each crate's `src/lib.rs`, domain `src/{entities,error,money,classification}.rs`, infrastructure `src/model/{mod,artifact,features,predict}.rs`, and `backend/crates/infrastructure/tests/model_parity.rs`.

**Interfaces:** `trait Classifier: Send + Sync { fn classify(&self, title: &str) -> AppResult<Classification>; }` in application `src/ports/classifier.rs`. `NativeClassifier::load(path: &std::path::Path) -> AppResult<Self>` implements it. `Classification` contains primary/secondary names, ordered probability vectors, and derived record type. `Money::positive(value: Decimal) -> AppResult<Money>` validates scale <= 2 and positive amounts.

- [ ] Write `parity_matches_python`, `empty_processed_title_matches_python`, `rejects_invalid_dimensions`, and `rejects_unknown_artifact_version`. Assert exact class labels and absolute probability error <= `1e-6`; malformed artifacts return `Unavailable`.
- [ ] Run `cargo test --manifest-path backend/Cargo.toml -p tracker-infrastructure --test model_parity`; expect failure before implementation.
- [ ] Implement workspace manifests and domain/port types. Implement artifact validation, ASCII preprocessing matching the reference, word/character grams, vocabulary counts, sublinear TF, separate vectorizer L2 normalization, direction features, and stable softmax. Use sparse feature evaluation; handle zero text norms.
- [ ] Run parity tests against Task 2's real artifact and broad corpus; expect all labels and probability comparisons to pass. Run `cargo fmt --manifest-path backend/Cargo.toml --all -- --check` and verify domain/application dependencies have no Furnace/SQLx coupling.
- [ ] Checkpoint backend boundaries and inference.

## Task 4: Persist authentication and profiles

**Files:** Create `backend/migrations/0001_tracker.sql`; application `src/ports/{auth,profiles}.rs`, `src/use_cases/{auth,profiles}.rs`; infrastructure `src/postgres/{mod,auth,profiles}.rs`, `src/security/{mod,passwords,tokens}.rs`; infrastructure `tests/auth_profiles.rs`.

**Interfaces:** `AuthRepository` provides `create_user(Credentials) -> AppResult<UserSummary>`, `authenticate(Credentials) -> AppResult<UserSummary>`, `save_session(Session) -> AppResult<()>`, `get_session(session_id: Uuid) -> AppResult<Session>`, `revoke_session(session_id: Uuid) -> AppResult<()>`. `ProfileRepository` provides `get(user_id: Uuid) -> AppResult<Profile>` and `rename(user_id: Uuid, username: String) -> AppResult<Profile>`. `TokenCodec` provides `issue(user_id: Uuid, session_id: Uuid) -> AppResult<TokenPair>` and separate `verify_access`/`verify_refresh` returning `TokenIdentity { user_id, session_id, expires_at }`. Auth use cases expose `register`, `login`, `validate`, `refresh`, and `logout` using those values.

- [ ] Add real PostgreSQL tests `register_login_logout`, `refresh_expiry_and_token_kind`, `rename_preserves_session`, and `duplicate_username_is_conflict`. Assert bcrypt verification, no refresh/access substitution, valid session enforcement, and revoked-session rejection.
- [ ] Run the tests with `TRACKER_TEST_DATABASE_URL` pointing to a disposable database; expect failure before adapters/migrations exist. Tests must refuse a non-test database, and missing test DB configuration must be reported as skipped, never passed.
- [ ] Implement migrations for users, sessions, categories, records/category joins, debts, friend requests/friendships, classifier feedback, Discord verifications, notification outbox, and report delivery keys. Use `NUMERIC(20,2)` for balances/amounts, explicit foreign keys/uniqueness, and seeded reference categories.
- [ ] Implement auth/profile adapters, bcrypt hashing, typed access/refresh claims, per-session token identities, expiration/revocation checks, and profile validation. Execute blocking password work outside async request workers. Public summaries exclude hashes.
- [ ] Run PostgreSQL tests; expect successful auth/profile behavior and safe duplicate handling. Checkpoint migrations and adapters.

## Task 5: Migrate record workflows atomically

**Files:** Create application `src/ports/records.rs`, `src/use_cases/records.rs`; infrastructure `src/postgres/records.rs`; infrastructure `tests/records.rs`.

**Interfaces:** `RecordRepository` provides `create(user_id: Uuid, command: CreateRecord, prediction: Classification) -> AppResult<Record>`, `list(user_id: Uuid) -> AppResult<RecordOverview>`, `commit(user_id: Uuid, command: CommitRecord) -> AppResult<Record>`, `delete_draft(user_id: Uuid, record_id: Uuid) -> AppResult<()>`. `RecordOverview` contains records and the user's cash/debt/receivable totals. `RecordUseCases::create` invokes Task 3's `Classifier` before storage; commit uses the repository's atomic operation.

- [ ] Add tests `create_classified_draft`, `secondary_only_correction_persists`, `commit_twice_changes_cash_once`, `concurrent_commit_changes_cash_once`, `invalid_category_rolls_back`, `other_user_cannot_modify`, and `committed_record_cannot_delete`. Assert corrected category/type, one feedback row and cash delta, and no partial updates.
- [ ] Run the record tests; expect failure before implementation.
- [ ] Implement ownership validation, strict date/amount/title validation, primary-secondary pair validation, default secondary when primary changes, row-locked commit, atomic cash/record/category/feedback changes, and transactional draft deletion. Enqueue optional notification work in the same transaction.
- [ ] Run record integration tests against PostgreSQL, including actual concurrent operations; expect one success/one conflict for concurrent commit and exact decimal cash totals.
- [ ] Checkpoint record workflows.

## Task 6: Migrate friendships and debts

**Files:** Create application `src/ports/{friends,debts}.rs`, `src/use_cases/{friends,debts}.rs`; infrastructure `src/postgres/{friends,debts}.rs`; infrastructure `tests/{friends,debts}.rs`.

**Interfaces:** `FriendRepository` provides `search(user_id: Uuid, name: String) -> AppResult<Vec<Friend>>`, `list(user_id: Uuid) -> AppResult<Vec<Friend>>`, `requests(user_id: Uuid) -> AppResult<Vec<FriendRequest>>`, `send(user_id: Uuid, friend_id: Uuid) -> AppResult<()>`, `respond(user_id: Uuid, request_id: Uuid, action: FriendAction) -> AppResult<()>`. `DebtRepository` provides `create(user_id: Uuid, command: CreateDebt) -> AppResult<Debt>`, `finish(user_id: Uuid, debt_id: Uuid) -> AppResult<Debt>`, `list_owned(user_id: Uuid) -> AppResult<Vec<Debt>>`, `list_owed(user_id: Uuid) -> AppResult<Vec<Debt>>`.

- [ ] Add tests `request_accept_reject`, `duplicate_and_self_request_rejected`, `request_receiver_authorized`, `debt_create_and_finish_balances`, `only_debtor_can_finish`, `concurrent_finish_once`, `self_debt_rejected`, and `debt_records_already_committed`. Assert unchanged balances after rejected operations and exact owner/debtor deltas matching the reference.
- [ ] Run the friend/debt tests; expect failure before implementation.
- [ ] Implement reciprocal reference friendship semantics, atomic request response, and row-locked debt transactions. Lock user rows in sorted UUID order. Generated ledger records are already committed; pending/completed statuses and frontend response fields stay compatible.
- [ ] Run all relevant integration tests and verify attempting to commit a debt-generated record returns conflict with unchanged balances.
- [ ] Checkpoint friends and debts.

## Task 7: Connect the API through Furnace

**Files:** Create `backend/src/main.rs`, `backend/furnace.toml`; HTTP `src/{cauldron,providers,dto,errors,auth,records,debts,friends,profiles,health}.rs`, `src/guards/session.rs`, `tests/contracts.rs`, and `tests/fixtures/contracts.json`.

**Interfaces:** Furnace controllers expose every route in the spec. `ApiResponse<T> { status: u16, message: String, data: T }` preserves the reference envelope. The composition root injects `Arc` use cases and adapters, loads config/model, applies migrations, binds `0.0.0.0:8080`, and shuts down managed resources. HTTP tests construct an in-process configured Furnace router and use real test DB adapters.

- [ ] Resolve the official Furnace release and verify a minimal controller/cauldron/provider/guard example compiles before committing to macros. Pin that version and lock dependencies; check package identity against the requested upstream. If network access remains unavailable, mark framework compilation blocked instead of inventing APIs.
- [ ] Capture request/response fixtures from reference services, controllers, DTOs, and Angular consumers. Add `route_contracts`, `protected_routes_require_session`, `cookie_flags_and_refresh`, `cross_origin_mutation_rejected`, and `public_payloads_exclude_secrets`. Assert frontend-consumed shapes, expected 400/401/403/404/409 statuses, and cookie policies.
- [ ] Run HTTP tests; expect failure before controllers exist.
- [ ] Implement real registered Furnace controllers/providers, guards and lifecycle wiring. Use HttpOnly/SameSite=Lax cookies with configurable Secure, host-only scope, path `/`, access lifetime 10 minutes and refresh lifetime 30 days. Check session validity and same-origin policy on authenticated mutations. Map infrastructure errors to safe responses.
- [ ] Implement `/health/live` for process liveness and `/health/ready` for database/model readiness. Run contract tests and a local register/login/classify/commit flow; expect frontend service compatibility.
- [ ] Checkpoint Furnace integration and lockfile.

## Task 8: Preserve optional Discord behavior

**Files:** Create application `src/ports/{discord,notifications}.rs`, `src/use_cases/discord.rs`; infrastructure `src/discord/{mod,bot,verification,notifications,scheduler}.rs`, `src/postgres/{discord,outbox}.rs`, and `tests/discord.rs`; HTTP `src/discord.rs`.

**Interfaces:** `DiscordRepository` provides `generate_code(user_id: Uuid) -> AppResult<DiscordVerification>`, `verify(code: String, discord_id: String, username: String) -> AppResult<()>`, `status(user_id: Uuid) -> AppResult<DiscordStatus>`, `disconnect(user_id: Uuid) -> AppResult<()>`, `set_notification(user_id: Uuid, kind: NotificationKind, enabled: bool) -> AppResult<()>`. `Notifier::send(message: NotificationMessage) -> AppResult<()>` abstracts Discord delivery. `DiscordRuntime::start(config, repository, notifier) -> AppResult<Self>` owns bot/scheduler handles; `shutdown(self)` joins them. `enqueue_weekly_report(user_id: Uuid, week_key: String) -> AppResult<bool>` uses a unique persisted key.

- [ ] Add `expired_and_reused_code_rejected`, `preferences_respected`, `disabled_bot_does_not_block_startup`, `notification_failure_keeps_commit`, and `weekly_restart_deduplicates`. Fake the notifier/clock while exercising persisted verification and delivery keys.
- [ ] Run tests; expect failure before implementation.
- [ ] Implement six-digit cryptographic codes with ten-minute expiry, single-use `/verify`, all profile Discord routes, commit outbox delivery, bounded retries, Saturday 20:00–20:04 Asia/Jakarta scheduling, weekly report calculations, and verification cleanup. Register the slash command with Tracker copy only when credentials enable the bot.
- [ ] Run adapter tests and cancellation/shutdown checks. If credentials exist, perform live Discord smoke verification; otherwise document that live verification was not run.
- [ ] Checkpoint Discord integration.

## Task 9: Package the complete deployment and feedback export

**Files:** Create `compose.yaml`, `.env.example`, `.dockerignore`, `README.md`, `app/Dockerfile`, `app/nginx/default.conf`, `backend/Dockerfile`, `training/Dockerfile`, `training/src/export_feedback.py`, and `training/tests/test_feedback_export.py`.

**Interfaces:** `docker compose up --build -d` starts healthy frontend/backend/PostgreSQL using the bundled artifact. `docker compose --profile training run --rm training` trains/exports offline; rebuilding backend promotes the artifact. `python training/src/export_feedback.py --database-url ... --output ...` exports confirmed feedback with `title,category,secondary_category,source,timestamp` columns. `.env.example` documents DB credentials, public port, token secrets, model path, cookie policy, allowed origin, and optional Discord credentials.

- [ ] Add feedback export test `csv_quotes_titles_and_preserves_labels` against a temporary test DB; assert correct quoting and only committed feedback export. Run it to observe failure before implementation, then implement/export and verify it passes.
- [ ] Write multi-stage frontend/backend Dockerfiles with exact artifact/output paths, nonroot backend, CA certificates/timezone data, read-only model, and health checks. Provide the offline training image. Keep build contexts narrow and reference files excluded.
- [ ] Write Compose with project name `tracker`, named PostgreSQL volume, health-based dependencies, private DB network, backend egress, restart policies, and no required external network. Training exists only in its profile. Use Compose-required values for secrets instead of shipping working production defaults.
- [ ] Run `docker compose --env-file .env.example config`; expect successful validation using documented local example settings. Build images and start the stack with a temporary populated environment file.
- [ ] Write README commands for local development, disposable test DB, deployment, startup/migrations, optional Discord, feedback export/retraining, parity verification, backend rebuild/restart, backup/restore, and environment limitations. Document the absence of online auto-retraining.
- [ ] Checkpoint deployment assets and documentation.

## Task 10: Verify the complete migration

**Files:** Create `scripts/smoke.mjs` for browser/API smoke verification; fix only migration-related failures; update README with observed validation.

**Interfaces:** Smoke uses two fresh users through the frontend URL and never operates on unrelated existing accounts. It checks same-origin browser cookies, navigation, classifications, friends/debts, profiles, persistence, and public JSON.

- [ ] Run Rust formatting, `cargo clippy --manifest-path backend/Cargo.toml --workspace --all-targets -- -D warnings`, workspace tests with the test DB configured, Python tests, model parity, and Angular production build. Record failures versus environment-blocked/skipped tests distinctly.
- [ ] Run the Compose stack and browser smoke: register two users; login; create/classify/commit a record; correct a category; send/accept friendship; create/settle debt; edit profile; logout. Assert balances and repeated-operation conflicts. Check only frontend/backend/PostgreSQL are persistent services.
- [ ] Restart the stack without deleting volumes and verify users, balances, records, and model readiness persist. Verify default deployment has no Go runtime, Python NLP server, or `SLM_URL` references.
- [ ] Review dependency boundaries, API coverage, real artifact provenance, Docker build exclusions, optional Discord lifecycle, and all five Review Focus cases. Fix discovered issues and rerun checks affected by those fixes.
- [ ] Provide an independent review if the selected execution workflow requires it, without claiming live external checks that were not run. Report changed paths, launch commands, completed checks, and concrete remaining limitations.

## Execution handoff

The user approved the design and selected direct implementation. Implementation files are delivered. Local verification and one independent review completed; Docker/live PostgreSQL/browser/Discord checks are blocked by environment access. See `docs/verification.md` for observed results, rulings, fixes, deferred minor findings, and remaining checks. Unchecked test/deployment steps must not be interpreted as passed.
