# Furnace-native backend refactor

User-directed continuation of the approved migration and direct implementation.

Inspect all nine upstream crates and the three examples at commit
`b8e8ae72504cad986355c11ceecab76f9370a6f2` (1.0.1). Import its native
`DatabaseCauldron`; inject its SeaORM connection directly into repositories.
Use entities for user/session CRUD and bound statements/native transactions for
financial queries, preserving transaction semantics. Provide repositories with
`#[storage]`, application adapters with `#[burner]`, and import/export them through
cauldrons. Domain/application remain independent of Furnace.

Replace manual startup with `Furnace::burn::<AppCauldron>()`. Native burn owns
configuration, listener binding, database readiness/close, and resource lifecycle.
Since burn does not expose a custom outer-router middleware hook, preserve origin
validation in mutating controllers and move automatic refresh to an explicit
cookie refresh endpoint plus the frontend's shared HTTP interceptor.

Steps:
1. Pin both published crates.io framework and persistence packages to `=1.0.1`.
2. Test graph/service injection, same-pool repository composition, refresh cookies,
   and origin rejection through the raw generated Furnace router.
3. Implement native database/service cauldrons, native input validation/cookies/JWT,
   and lifecycle contributions.
4. Use burn startup; update Docker/Compose/Furnace config and local instructions.
5. Verify Rust workspace tests, formatting, Clippy, Angular build, Compose config;
   document environment-blocked live checks.

Offline verification may seed temporary Cargo Git caches from the clean local
upstream checkout. Temporary verification overrides remain outside the product;
product dependencies use crates.io and never an absolute local path or Git patch.

Implementation complete: native configuration/composition, persistence pool
sharing, migration/worker lifecycle, validation, cookies, JWT, CORS and burn
startup are in place. Transport contracts and frontend refresh regressions pass.
Independent review found no Critical/Important defects; the minor JWT claim-policy
difference was corrected. Final evidence and blocked deployment checks are recorded
in `docs/verification.md`. The published registry archives subsequently became available; retain the registry
lockfile and verify without the temporary upstream override. The user additionally
required SeaORM for all database access: repository and worker queries, transactions,
and migration execution now use SeaORM. Add migration rollback/checksum tests.
