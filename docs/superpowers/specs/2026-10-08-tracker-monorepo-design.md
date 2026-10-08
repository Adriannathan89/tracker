# Tracker monorepo migration design

Date: 2026-10-08
Status: Approved by the user; implementation has not started.

## Outcome and scope

Create a monorepo at `/home/ryynn/Desktop/tracker` with the existing Angular frontend in `app/`, renamed to `tracker`, and a Rust backend in `backend/` using furnace-rs and clean architecture. Keep Python for offline model training and export only; inference runs inside the Rust backend. Supply Dockerfiles and a root Compose stack for the frontend, backend, and PostgreSQL.

Preserve the reference application's authentication, records, category corrections, balances, debts, friends, profiles, Discord verification, commit notifications, and weekly reports. Keep the current UI and Indonesian transaction categories. Do not introduce a frontend framework migration or a new UI design.

Confirmed database requirement: a fresh Tracker database with the existing app features preserved. Importing existing production data is outside scope. No existing database is modified by this design.

## Findings from the reference

- `reference/bayarWoyFE`: Angular 21, TypeScript, Tailwind, Angular Material, Axios, and npm. Package and Angular project names still identify BayarWoy. Several UI labels and SVG wordmarks also contain the old name.
- `reference/bayarwoyBE`: Gin/GORM backend with PostgreSQL, bcrypt passwords, access/refresh cookies, persisted sessions, records, debts, friendships, profiles, and a Discord bot.
- `reference/bayarwoy-slm`: scikit-learn classifier, not a generative language model. It combines word TF-IDF (1–2 grams), character TF-IDF (`char_wb`, 3–5 grams), and eight money-direction features. Two logistic regressions predict primary and secondary categories. Income/expense is derived from the primary category. A trained `classifier.joblib` and training data are present.
- The Go backend currently makes HTTP calls to the Python service for classification and feedback. The Python server can retrain from feedback; this becomes an offline operation.
- `app/` currently has only Git metadata. The workspace root does not have a usable Git repository. Implementation must avoid overwriting or removing that metadata; repository ownership can be normalized separately if requested.

## Approaches considered

1. **Recommended: Python training, portable parameter artifact, native Rust inference.** Export vocabularies, IDF values, preprocessing settings, direction cues, class order, coefficients, and intercepts to versioned JSON. Rust implements the existing feature extraction and probability calculation. This fits the small linear model and keeps the runtime image free of Python and an additional inference runtime. Cross-language parity tests are required.
2. **ONNX export and in-process Rust ONNX inference.** Useful if the model changes to a neural network, but the custom money-direction transformer and text preprocessing still need a verified conversion or Rust implementation. Adds runtime packaging complexity for the present model.
3. **Embed Python in the Rust process.** Reuses joblib directly but retains Python, scikit-learn, and interpreter management in deployment. This weakens the intended separation between training and the application runtime.

Do not replace trained predictions with keyword rules. The selected artifact remains a trained classifier. Do not expose the old Python classification/retraining service in Compose.

## Repository layout

```text
tracker/
  app/                      Angular application, package/project name tracker
    Dockerfile
    nginx/default.conf
  backend/
    Cargo.toml              Rust workspace
    Cargo.lock
    crates/
      domain/               Entities, value types, business rules, domain errors
      application/          Use cases and repository/classifier/notifier ports
      infrastructure/       PostgreSQL, model, password/token and Discord adapters
      http/                 Furnace controllers, DTOs, guards, error mapping
    src/main.rs             Composition root and application lifecycle
    migrations/             Explicit, versioned PostgreSQL migrations
    Dockerfile
    furnace.toml
  training/
    src/                    Training, artifact export and parity fixture generation
    data/                   Curated reference training data
    requirements.txt        Training dependencies; no FastAPI or Uvicorn
    Dockerfile              Optional one-shot training image
  models/                   Versioned inference artifact and provenance metadata
  compose.yaml
  .env.example
  .dockerignore
  README.md
  docs/
  reference/                Original sources retained as migration reference
```

Copy source/configuration deliberately. Exclude dependency directories, virtual environments, build outputs, secrets, and nested Git metadata from reference copies and Docker contexts. The existing `app/.git` remains intact.

## Clean architecture and Furnace integration

Dependencies point inward: domain has no Furnace or SQL dependencies; application depends on domain and defines ports; infrastructure implements those ports; HTTP calls application use cases. The executable wires concrete adapters to use cases through explicit Furnace cauldrons and providers. Furnace provides real application composition, controllers, guards, configuration, and lifecycle management rather than being an unused dependency.

Split use cases by auth, records, debts, friendships, profiles, and Discord linking. Repository interfaces expose complete transactional operations where atomicity matters; avoid leaking SQL transactions or database pools into domain entities or controllers.

Use the official `furnace-rs` package and the APIs documented by the requested repository. Resolve and pin a compatible release when implementation starts. The published facade documents explicit cauldron registration, HTTP controllers, JWT/cookie guards, and lifecycle hooks. The requested GitHub pages could not be fetched in this environment; the public crate documentation was available through search. Verify the chosen version against compilable examples before building the full adapter layer.

Documentation sources:

- Requested source: https://github.com/Adriannathan89/furnace-rs
- Published facade: https://docs.rs/furnace-rs/latest/furnace_rs/
- Core contracts: https://docs.rs/furnace-rs-core/latest/furnace_rs_core/

## HTTP and frontend compatibility

The browser uses the same-origin `/api` prefix. Nginx proxies `/api/` to the backend and removes the prefix; Rust preserves the reference route paths. Local Angular development uses an equivalent dev-server proxy.

Preserve request field names, response envelopes, and the frontend's camelCase JSON contract. Do not return password hashes or session secrets. Replace all product labels, package names, Angular build targets/output paths, document titles, and old wordmark assets with Tracker naming. Preserve normal Indonesian words such as `bayar` in transaction UI.

Route families to migrate:

| Area | Routes |
| --- | --- |
| Authentication | `POST /auth/login`, `POST /auth/logout`, `GET /auth/validate-session`, `POST /user/register` |
| Records | `POST /user/record`, `GET /user/records`, `PUT /user/record/commit`, `DELETE /user/record/{id}` |
| Debts | `POST /debt/create`, `PUT /debt/finish`, `GET /debt`, `GET /debt/owed` |
| Friends | `POST /user/friend/add`, `POST /user/friend/search`, `GET /user/friend/request`, `GET /user/friend`, `PUT /user/friend/request/response` |
| Profile | `GET /user/profile`, `PUT /user/profile` |
| Discord | `POST /user/discord/verify`, `GET /user/discord/status`, `DELETE /user/discord`, `PUT /user/discord/notification` |
| Operations | `GET /health/live`, `GET /health/ready` |

Retain bcrypt compatibility and persisted refresh sessions. Use HttpOnly, SameSite=Lax cookies for the same-origin deployment, configurable Secure for local HTTP versus HTTPS hosting, access/refresh token separation, refresh expiration checks, and logout revocation. Validate the request origin on cookie-authenticated state changes. Check authentication and ownership for every protected operation.

## PostgreSQL and financial consistency

Use SQLx PostgreSQL adapters and explicit migrations instead of GORM auto-migration. Preserve UUID identities and externally visible fields. Store money as fixed precision numeric values and use decimal arithmetic internally; convert at the JSON boundary without changing frontend field shapes.

Record creation classifies a title and stores an uncommitted record. Commit resolves and validates primary/secondary categories, derives income or expense, updates cash, marks the record committed, and stores confirmed training feedback atomically. A second commit returns conflict. Delete permits only the owner's uncommitted records.

Debt creation and completion update both users' balances and the debt status in one transaction. Lock affected users in deterministic order and the relevant debt/record row to prevent concurrent lost updates. Only the debtor may complete a pending debt. Reject self-debts and nonpositive amounts. Debt-generated records must already be committed because their cash effects have already been applied; this avoids double-counting through the normal commit endpoint.

Friend acceptance atomically removes the request and creates the reference friendship representation. Reject duplicate/self requests and unauthorized responses.

Translate validation, unauthorized access, forbidden actions, missing objects, and repeated operations into 400/401/403/404/409 responses. Keep internal database/configuration errors out of client messages.

## Training and in-process inference

Training keeps the curated dataset and existing two-classifier design. Export a portable artifact with a format version, training provenance, preprocessing configuration, each vectorizer's vocabulary and IDF, the money feature definitions/order, ordered classifier classes, coefficients/intercepts, and category/type metadata. Include a checksum and metrics alongside the artifact.

Rust loads and validates the artifact once at startup: version, finite numbers, dimensions, vocabulary indices, class order, and expected feature counts. Preprocessing, word/character n-gram generation, sublinear TF, per-vectorizer L2 normalization, direction features, and stable softmax must match Python. Compute only features present in the trained vocabulary.

Generate fixtures from Python with predicted labels and unrounded probabilities. Rust must match both labels and probabilities within an agreed numerical tolerance (initial target: absolute error <= 1e-6). Fixtures cover income/outflow contrasts, punctuation, stopwords, repeated whitespace/tokens, unknown words, and empty input after preprocessing. Run a broader corpus parity check in addition to fixed examples.

Fail startup/readiness clearly when the required model is missing or invalid. Bound title length and move CPU-bound work off async request workers if profiling shows it is needed. The runtime must not silently fall back to an untrained classifier.

Confirmed categories are saved to a PostgreSQL feedback table; export them with an offline command for later training. Retraining is an explicit training job, followed by parity verification and artifact promotion. Backend restart loads the new artifact. Remove automatic retraining during HTTP requests and remove `SLM_URL` configuration.

## Discord integration

Keep Discord optional and run the bot, verification handler, notification adapter, and scheduler within the main backend process. Enable them only with configured credentials. Preserve the six-digit expiring verification flow, `/verify` command, notification preferences, commit notifications, and Saturday 20:00 Asia/Jakarta weekly report schedule.

Discord failures must not roll back successful financial transactions. Lifecycle shutdown stops background tasks and the connection. Use persisted delivery/job identifiers to prevent normal restart/scheduler duplication. Explicitly document that external delivery may still require retry handling and cannot be guaranteed exactly once.

## Docker deployment

The default Compose project name is `tracker`. It starts three persistent services:

- `frontend`: multi-stage Node build and Nginx runtime, SPA fallback, `/api` reverse proxy, public port configurable with a localhost-friendly default.
- `backend`: multi-stage Rust release build and a nonroot runtime with CA certificates and timezone data, bundled read-only model artifact, environment configuration, database migration at startup, liveness/readiness checks.
- `postgres`: PostgreSQL with a named persistent volume and readiness check; no public database port in the default deployment.

The backend waits for healthy PostgreSQL; the frontend starts after backend readiness. Keep backend/database communication on an internal network, with a backend egress network for Discord when enabled. Supply restart policies and graceful stop timeouts. No external pre-created network is required.

Provide a `training` Compose profile with a one-shot Python job that writes to `models/`; it is not part of the running application. Document training/export, backend rebuild, and artifact promotion separately from `docker compose up --build`. Include a valid tested artifact so the normal startup command does not require training first.

`.env.example` contains placeholders and documented local settings. Real secrets are excluded from images and source copies. Docker builds exclude reference dependency trees and virtual environments.

## Verification and completion criteria

1. Angular production build and relevant existing tests pass under the `tracker` project name.
2. Rust formatting, workspace build, lint, and meaningful unit/integration tests pass.
3. HTTP contract tests cover all route families and authentication/ownership failures.
4. PostgreSQL integration tests exercise transaction rollback, repeated/concurrent commits, debt settlement, category changes, and friendship acceptance.
5. Python training/export tests and cross-language inference parity checks pass using the actual learned artifact.
6. Compose configuration validates; images build; the stack reaches healthy state; browser smoke checks cover register/login, draft/classify/commit, friend request/acceptance, debt creation/settlement, and profile editing.
7. Restart preserves data and model behavior. Normal deployment contains no Go backend or Python NLP server. Optional Discord is verified with adapter tests and, when credentials are provided, an external integration smoke check.
8. README supplies exact local development, Compose deployment, configuration, migration, training, and model update commands. Report any environment-blocked checks accurately.

## Environment constraints observed

Direct shell downloads currently fail DNS resolution and the requested GitHub pages return cache misses through browsing. Dependency installation and container builds may require a network-enabled environment. This is a verification constraint, not a reason to substitute a different framework or claim unexecuted checks passed.

The root `.git` directory is a read-only environment mount and is not a valid repository; the empty `app/` has its own Git metadata. Save the reviewed design in the workspace without attempting to rewrite repository metadata or claiming a design commit exists.
