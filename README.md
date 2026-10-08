# Tracker

Tracker is a monorepo containing the Angular web app, a Flutter Android client, and a Rust backend built with [furnace-rs](https://github.com/Adriannathan89/furnace-rs). It preserves authentication, financial records, debts, friends, profiles, and optional Discord integration. This deployment starts with a fresh PostgreSQL database.

| Path | Purpose |
| --- | --- |
| `app/` | Angular 21 frontend, package/project name `tracker` |
| `mobile/` | Flutter/Dart Android app, same Tracker API and mobile design |
| `backend/crates/domain/` | Entities, decimal amounts, business validation |
| `backend/crates/application/` | Use cases and repository/classifier/security ports |
| `backend/crates/infrastructure/` | PostgreSQL, native trained inference, bcrypt/JWT, Discord |
| `backend/crates/http/` | Furnace controllers, cookie guards, HTTP DTO/error mapping |
| `backend/src/main.rs` | Composition root, resource lifecycle, server |
| `training/` | Offline Python training, model export, feedback export |
| `models/` | Trained JSON artifact and checksum/provenance manifest |
| `reference/` | Original application sources; excluded from Docker builds |

Dependencies point inward. Domain and application have no Furnace or database dependencies. The backend uses feature cauldrons, `#[storage]` PostgreSQL repositories, and a `#[burner]` adapter binding application ports with `provide_with`. `Furnace::burn` loads configuration, applies CORS, constructs providers, and manages startup/shutdown. Native `DatabaseCauldron` supplies one SeaORM PostgreSQL connection; repositories use SeaORM entities, parameterized statements, and native transactions on that connection. Furnace's `JwtService`, Passport guards, `CookieJar`, and `Input`/`ValidatedJson` provide authentication, cookies, and request validation. Money uses `NUMERIC(20,2)` and Rust decimals; JSON values remain numbers for frontend compatibility. See [the Furnace inspection](docs/furnace-patterns.md).

Framework and persistence dependencies pin the published crates.io packages to `=1.0.1`, with `backend/Cargo.lock` retained for locked builds. Local verification uses the published registry packages. SQLx is only a test fixture dependency; application database access goes through SeaORM.

## Run the full application

For the Android client and APK build instructions, see [mobile/README.md](mobile/README.md). The Android app uses the same deployed backend at `https://tracker.adrianportofolio.my.id/api/` by default.

Requirements: Docker Engine and Docker Compose v2.

```bash
docker compose up --build -d
docker compose ps
```

Compose includes local defaults: PostgreSQL user/database/password `tracker`, a development signing secret, and frontend port `8080`. To override them, copy `.env.example` to `.env` and edit the values. For deployment, replace both secrets; `TOKEN_SECRET` must contain at least 32 bytes and the database password must use URL-safe characters.

Open **http://localhost:8080**. Nginx serves Angular and proxies `/api/*` to Rust. Only the frontend port is public. The backend applies versioned migrations, checks the model checksum, and loads inference once before accepting requests. PostgreSQL stores data in the `tracker_tracker_postgres` named volume.

Change both `FRONTEND_PORT` and `PUBLIC_ORIGIN` when choosing another public port. For an HTTPS deployment, set `PUBLIC_ORIGIN` to the exact public origin without a trailing slash, enable `COOKIE_SECURE=true`, and put an HTTPS reverse proxy in front of the frontend. Local HTTP defaults use HttpOnly, SameSite=Lax cookies with Secure disabled. State-changing requests with another Origin or `Sec-Fetch-Site: cross-site` are rejected.

```bash
docker compose logs -f backend
docker compose stop
docker compose start
```

Normal `docker compose down` preserves the volume. `docker compose down -v` deletes the database; use it only when intentionally resetting local data. Migrations are explicit and automatically applied; the Go database is not imported or modified.

## Local development

Requirements: Node 24/npm, Rust 1.94 or newer, Python 3.12 for training, PostgreSQL 16. On Debian/Ubuntu, install `libcrypt-dev` for native bcrypt linkage and the compiler/CMake prerequisites used by Rust dependencies.

```bash
cd app
npm ci
npm start
```

Angular runs at http://localhost:4200; its dev proxy sends `/api` to the backend at http://127.0.0.1:8080. No frontend `.env` is required. `TRACKER_API_BASE_URL` overrides `/api` if set in the environment or optional `app/.env`.

In another terminal, from the monorepo root:

```bash
cd backend
cp -n .env.example .env
# Edit .env: set DATABASE_URL to your local PostgreSQL credentials and replace
# TOKEN_SECRET with the output of: openssl rand -hex 32
furnace dev
```

The default Compose database has no host port. Use an independently managed local PostgreSQL instance for this command or a local Compose override to expose a database port.

Run `furnace dev` or `cargo run -p tracker-backend` from `backend/` so `Furnace::burn` finds `furnace.toml`. It reads optional `backend/.env` for interpolation, then TOML, then `FURNACE_*` overrides. The root `.env` is for Compose; Furnace does not automatically read that parent file. TOML uses `DATABASE_URL`, `TOKEN_SECRET`, `PUBLIC_ORIGIN`, and `COOKIE_SECURE`; you can also export these variables instead of creating `backend/.env`. Native listener overrides are `FURNACE_SERVER__HOST` and `FURNACE_SERVER__PORT`, and the model override is `FURNACE_TRACKER__MODEL_PATH`. Set `FURNACE_FURNACE__MODE=debug` for native request logging.

Optional Discord configuration uses `FURNACE_TRACKER__DISCORD__BOT_TOKEN`, `FURNACE_TRACKER__DISCORD__CLIENT_ID`, `FURNACE_TRACKER__DISCORD__PUBLIC_KEY`, and `FURNACE_TRACKER__DISCORD__BOT_USERNAME`. Compose maps the existing `.env` Discord variables to these native overrides.

Secrets are never included in public user payloads. Access tokens last ten minutes; persisted refresh sessions last thirty days. The frontend renews cookies with `POST /auth/refresh` and retries once on an expired access token, sharing one refresh across concurrent requests. Logout revokes the session, including its access token. Renaming a user does not invalidate their session. Furnace input validation returns 422 with field issues in its native `error` envelope; application use cases retain domain checks for non-HTTP callers.

## Train and update the classifier

The reference NLP model is a trained scikit-learn classifier, using word/character TF-IDF and money-direction features with two logistic regressions. Rust loads the learned vocabularies, IDF values, coefficients, class order, and preprocessing metadata directly. There is no Python server or HTTP inference dependency in the application runtime.

A trained artifact is included. To train explicitly:

```bash
python3.12 -m venv training/.venv
training/.venv/bin/pip install -r training/requirements.txt
OPENBLAS_NUM_THREADS=1 training/.venv/bin/python training/src/train.py
PYTHONPATH=training/src training/.venv/bin/python -m pytest training/tests
cargo test --manifest-path backend/Cargo.toml -p tracker-infrastructure --test model_parity
```

Or use the one-shot Compose training profile:

```bash
docker compose --profile training run --build --rm training
```

Training writes `models/transaction-model.json`, `models/manifest.json`, and Python-generated parity fixtures. Run the parity tests **before promoting** a new artifact; labels must match, and absolute probability error must be <= `1e-6`. The manifest records dataset hash, model SHA-256, library versions, metrics, and timestamp. Missing, invalid, or mismatched artifacts prevent backend startup.

The bundled artifact was trained on 15,226 reference samples. Its five-fold mean accuracy is 98.80% for primary categories and 95.55% for secondary categories; see `models/manifest.json` for provenance. These are training-validation metrics, not a guarantee for unseen user transactions.

Confirmed category corrections are stored transactionally in PostgreSQL. Export and retrain explicitly:

```bash
export DATABASE_URL='postgresql://tracker:YOUR_PASSWORD@HOST:5432/tracker'
training/.venv/bin/python training/src/export_feedback.py --output training/data/feedback.csv
OPENBLAS_NUM_THREADS=1 training/.venv/bin/python training/src/train.py --feedback training/data/feedback.csv
cargo test --manifest-path backend/Cargo.toml -p tracker-infrastructure --test model_parity
docker compose up -d --build backend
```

The exporter needs network access to PostgreSQL; use a host/database connection appropriate to your environment. Feedback files are ignored by Git. The backend loads updated models on restart; it never retrains during requests. Back up the previous artifact/manifest together before promotion so rollback is a backend rebuild with that pair restored.

## Optional Discord integration

Set `DISCORD_BOT_TOKEN`, `DISCORD_CLIENT_ID`, and `DISCORD_PUBLIC_KEY` in `.env`; optionally set `DISCORD_BOT_USERNAME`. Leave the token blank to disable Discord. No additional bot container is needed.

The migration uses Discord's [signed HTTP interactions](https://docs.discord.com/developers/interactions/receiving-and-responding) instead of a persistent Gateway connection. Configure the Developer Portal's **Interactions Endpoint URL** as `https://YOUR_HOST/api/discord/interactions`. This must be reachable through HTTPS; localhost alone is insufficient. The backend validates Ed25519 signatures and timestamp freshness before processing requests, and registers the `/verify code` command when enabled.

Users generate a ten-minute, six-digit code in Profile and invoke `/verify` in Discord. Codes are single-use; regenerating or disconnecting clears obsolete verification state. Commit/weekly preferences remain available. Commit notifications use a persisted outbox so Discord failures do not reverse financial commits. Weekly reports run Saturday at 20:00 Asia/Jakarta, covering Sunday 00:00 through Saturday 20:00 (exclusive), with the top three primary expense categories; persisted user/week keys avoid normal restart duplication. Deliveries retry at most five times. A crash after Discord accepts a message can still cause a duplicate; external delivery is not exactly once.

## Verification

```bash
npm --prefix app run build
(cd app && node scripts/tests/generate-env.test.mjs)
node app/scripts/tests/session-refresh.test.mjs
PYTHONPATH=training/src training/.venv/bin/python -m pytest training/tests
cargo fmt --manifest-path backend/Cargo.toml --all -- --check
cargo clippy --manifest-path backend/Cargo.toml --workspace --all-targets -- -D warnings
cargo test --manifest-path backend/Cargo.toml --workspace
docker compose --env-file .env.example config --quiet
```

Database integration tests are explicitly ignored in the normal suite because they require a disposable PostgreSQL database whose name ends in `_test`. They exercise auth/session revocation, ownership, category correction, concurrency, friendship acceptance, debt settlement, and already-committed debt ledger entries. Run them explicitly:

```bash
docker compose exec postgres createdb -U tracker tracker_test
# Uses a one-shot Rust build/test image connected to the private database network:
docker compose --profile test run --build --rm backend-tests
```

Or against a local test database:

```bash
export TRACKER_TEST_DATABASE_URL='postgresql://tracker:YOUR_PASSWORD@127.0.0.1:5432/tracker_test'
cargo test --manifest-path backend/Cargo.toml -p tracker-infrastructure --test workflows -- --ignored
```

For an API smoke check with limited browser checks while the stack is running:

```bash
cd app
npx playwright install chromium
cd ..
TRACKER_URL=http://localhost:8080 TRACKER_CHECK_RESTART=1 node scripts/smoke.mjs
```

The smoke creates two uniquely named test users in the selected deployment. With `TRACKER_CHECK_RESTART=1`, it recreates only the backend and verifies proxy recovery and persisted balances/sessions. Nginx re-resolves the backend through Docker DNS. It checks browser loading/cookies plus record classification/correction, friendship, debt settlement, profile rename, and logout. After restarting the stack, rerun a login/check with those users to verify volume persistence. Use a local/test deployment for these checks.

## Backup and restore

```bash
docker compose exec -T postgres pg_dump -U tracker -d tracker > tracker-backup.sql
# Restore only into a fresh database chosen for restoration:
docker compose exec -T postgres psql -U tracker -d RESTORE_DATABASE < tracker-backup.sql
```

Adjust user/database names if configured differently. Back up both database data and the model artifact/manifest. Passwords use native libxcrypt bcrypt (cost 12), included by the backend Dockerfile. Financial commits/debt settlement use row locks and atomic updates to prevent repeated requests from applying money movements twice.

See `docs/verification.md` for checks actually run in the migration environment and the checks that require a Docker/network-enabled host.
