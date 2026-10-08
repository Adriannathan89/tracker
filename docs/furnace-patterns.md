# Furnace integration inspection

Inspected the clean local upstream checkout at commit
`b8e8ae72504cad986355c11ceecab76f9370a6f2`, whose workspace is 1.0.1.
The local README's prepared-release note is stale: the user confirmed publication
and the docs.rs package feature page reports 1.0.1. Product dependencies pin the
published crates.io packages to `=1.0.1`.
Online GitHub access failed in this environment; the local checkout supplied
the source and all three examples.

## Crate responsibilities and patterns

| Crate | Inspected APIs and application use |
| --- | --- |
| `furnace-rs` | Feature matrix, public re-exports/prelude; use the facade for framework APIs rather than depending on implementation crates. |
| `furnace-rs-core` | Root graph, explicit imports/exports, `provide_with`, typed configuration, `Secret`, and contributed lifecycle resources. Domain/application remain independent. |
| `furnace-rs-core-macros` | `cauldron`, `burner`, `storage`, `Configuration`, and entry-point expansion. Managed fields become typed injector dependencies. |
| `furnace-rs-common` | Standard burn/config loader, router/preflight, CORS, JWT auto-configuration, Passport strategies, native cookies, input validation, and HTTP errors. |
| `furnace-rs-common-macros` | Controller/endpoint generation, body extractor order, static seals, guard and strategy metadata. |
| `furnace-rs-persistence` | Separate explicit dependency; native SeaORM PostgreSQL connection exported by global `DatabaseCauldron`, readiness ping and graceful close. Does not apply migrations. |
| `furnace-rs-testing` | Focused provider/controller fixtures; scripted SQLite SeaORM mocks do not prove PostgreSQL transactions. |
| `furnace-rs-cli` | Standard burn enables side-effect-free doctor/graph/routes inspection; scaffold follows cauldron/controller/burner layout. |
| `furnace-rs-extra` | Reserved boundary; no additional runtime capabilities. |

Cross-checked hello-world, posts-crud, and protected-route examples, workspace
architecture, facade/common/core/persistence guides, and owning runtime source.

## Decisions for Tracker

- Use `Furnace::burn::<AppCauldron>()`, with native persistence and service/HTTP
  cauldrons. Keep framework configuration in `backend/furnace.toml` and copy it
  into the container working directory.
- Configure explicit credentialed `[server.cors]` origins/methods/headers in TOML.
  CORS is a browser response policy; application origin/CSRF validation remains.
- Use Furnace's auto-configured `JwtService` through the existing application
  `TokenCodec` port, native `CookieJar` response composition, and Passport seals.
  Retain compatible application success/error JSON and domain validation.
- Use `#[storage]` for PostgreSQL repositories and `#[burner]` for an injected
  application-service adapter. Use `provide_with` for trait-object ports, so
  framework dependencies do not enter the domain/application crates.
- Inject the native SeaORM connection directly into `PgStore`. User/session CRUD
  uses entities and active models; financial joins, row locks, CTEs, and outbox
  queries use bound SeaORM statements and `DatabaseTransaction`. Direct SQLx is
  limited to socket-free test fixtures. No second pool.
- Apply the embedded schema through an atomic SeaORM transaction, an advisory
  startup lock, and a version/checksum ledger. Workers depend on the migration
  provider so migration startup precedes worker startup.
- Migrations and optional Discord worker are application lifecycle hooks;
  persistence owns database readiness and shutdown. Model loading is an injected
  startup requirement and remains in-process.
- Standard burn offers no public custom outer-router middleware hook. Move
  cookie renewal to `/auth/refresh` and automatic frontend retry; perform origin
  checks in the session strategy and public auth handlers.

## Source anchors

All paths below are relative to the upstream repository:
`crates/furnace-rs/src/lib.rs`, `crates/furnace-rs-core/src/{builder,cauldron,injector,lifecycle}.rs`,
`crates/furnace-rs-core-macros/src/managed.rs`,
`crates/furnace-rs-common/src/{server,server_config,router,cors,cookie}.rs`,
`crates/furnace-rs-common/src/jwt/{service,auto_configuration}.rs`,
`crates/furnace-rs-common/src/passport/{context,strategy,guard}.rs`,
`crates/furnace-rs-common-macros/src/{endpoint,controller/endpoints}.rs`,
`crates/furnace-rs-persistence/src/sea_orm/{mod,config,connector,lifecycle}.rs`,
and `example/{hello-world,posts-crud,protected-route}`.
