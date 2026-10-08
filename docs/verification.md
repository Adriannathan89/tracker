# Tracker migration verification

Date: 2026-10-08. Implementation delivered in the authorized workspace. External deployment verification remains pending.

## Furnace-native 1.0.1 continuation

The backend now pins `furnace-rs` and `furnace-rs-persistence` to the published
`=1.0.1` packages. It uses native cauldrons, burners, storage, database lifecycle,
JWT, cookies, `Input`/`ValidatedJson`, TOML CORS, and `Furnace::burn`. Inspection
details are in [furnace-patterns.md](furnace-patterns.md).

Initial verification used a temporary upstream-source override while packages
were unavailable. The published 1.0.1 archives subsequently became available in
the Cargo cache. Final checks use the published registry packages without that
override, and `backend/Cargo.lock` retains their registry sources/checksums.
Docker builds with `--locked`.

The user's subsequent SeaORM requirement supersedes the initial SQLx adapter:
`PgStore` now injects Furnace's SeaORM `DatabaseConnection` directly. Users and
sessions use entity/active-model CRUD. Financial queries and the Discord worker
use bound SeaORM statements and native transactions. Migration execution uses
an atomic SeaORM transaction, a serialized startup lock, and a version/checksum
ledger. Four scripted SeaORM tests cover fresh application, unchanged restart,
checksum mismatch rollback, and schema-failure rollback; these are mock checks,
not live PostgreSQL transaction evidence.

The continuation's runnable Rust suite has 24 tests: HTTP contracts 8, native
composition/pool sharing 2, SeaORM migration checks 4, model parity/artifacts 4,
security 2, Discord 4.
Seven PostgreSQL workflows remain explicitly ignored. Native HTTP tests cover
credentialed CORS, origin rejection, aggregate field validation, cookie refresh,
and authentication. Composition tests prove that the repository and native
database share the same pool and close state without opening a socket.
Three frontend refresh tests cover concurrent renewal, failed renewal, and login
failure; three environment-generator checks also pass. The Angular production
build passes. Rust formatting, workspace/all-targets Clippy with warnings denied,
and the backend executable build all pass. Compose configuration passes with
both training and test profiles using `.env.example`.

A fresh independent review found no Critical or Important defects. Its minor
finding was inconsistent JWT claim checks in the access strategy; access and
refresh now both require matching subject/user IDs, reject future-issued tokens,
and check expiry conversion.

A follow-up review of the SeaORM migration found no Critical or Important
defects in the inspected entity operations, parameter conversion, repository
transactions, error mapping, migration rollback/checksums, and hook ordering.
It did not independently run Cargo or re-review every worker query. The new
`tracker_migrations` ledger targets the approved fresh-database deployment; it
does not recognize a database initialized by the earlier SQLx prototype's
`_sqlx_migrations` ledger. Upgrading such a deployment requires a ledger
transition before startup.

Continuation rulings: use native SeaORM connections/entities/statements/transactions; retain application origin checks alongside native CORS; use the
native 422 validation envelope while retaining domain rules; implement explicit
refresh with one shared frontend retry; contribute migrations and Discord work
to native lifecycle hooks. Embedded migrations are registered explicitly in
`PgStore::migrate`; future migrations must be added there. Live migration/worker
startup, clean network installation, Docker startup, and PostgreSQL workflow
execution remain unverified under the environment restrictions below.

## Earlier migration checks (historical baseline)

| Check | Result |
| --- | --- |
| Angular production build (`npm --prefix app run build`) | Passed; output `app/dist/tracker/browser` |
| Frontend environment generator | 3 tests passed: default `/api`, process environment precedence, safe quoting |
| Python export/feedback suite | 2 tests passed; scikit-learn/SciPy emitted two upstream optimizer deprecation warnings |
| Offline classifier training | Completed with 15,226 samples; five-fold mean primary accuracy 0.9880466455 and secondary accuracy 0.9554708051 |
| Rust model parity | 267 Python-generated cases; exact label matches and absolute probability error <= 1e-6 |
| Rust workspace suite | 13 runnable tests passed, 7 PostgreSQL workflow tests explicitly ignored |
| Rust backend executable build | Passed using official cached Furnace 1.0.0 and locked dependencies |
| Rust formatting | Passed |
| Clippy workspace/all-targets with warnings denied | Passed |
| PostgreSQL migration | Applied successfully in PostgreSQL 16 single-user mode; 51 category rows seeded |
| Static SQL preparation | 56 distinct static SELECT/INSERT/UPDATE/DELETE/CTE statements prepared successfully after the final changes |
| Compose configuration | Passed including training/test profiles, using `.env.example` |
| JavaScript syntax | Environment generator and API/browser smoke script passed syntax checks |

Rust test breakdown: HTTP contracts 3, model artifact/parity 4, bcrypt/JWT 2, Discord signatures/window/report formatting 4. The HTTP tests construct real Furnace cauldrons/controllers/Passport guards and use an in-memory repository fixture to isolate the transport; they do not prove live database adapter behavior.

The parity corpus includes income/outflow contrasts, punctuation and stopword-only titles, unknown text, repeated tokens/whitespace, and Unicode text. Artifact version, malformed dimensions, and checksum tampering are rejected.

Local checks reused reference frontend dependencies through an ignored `app/node_modules` symlink and the reference Python virtual environment. Rust needed a writable temporary Cargo source location because the normal registry cache is read-only. Neither workaround is required by the committed Docker/source configuration; normal environments use `npm ci`, a training virtual environment, and Cargo.

## Checks blocked by this environment

- Docker daemon access is denied. Images were not built, and container startup/health checks, runtime library packaging, private-network communication, Nginx configuration execution, backend replacement recovery, and PostgreSQL volume persistence were not tested live.
- PostgreSQL socket creation is denied even for Unix sockets. Single-user mode validates schema and prepared SQL only. It does not execute the Rust repository workflows or verify concurrent transactions.
- Seven live integration tests remain explicitly ignored: repeated/secondary-only record commit; concurrent commit; ownership/category rollback; debt settlement and generated ledger records; friend request authorization/acceptance/search status; login/logout/rename session continuity; Discord code expiry/reuse/preferences and persisted weekly deduplication.
- The browser/API smoke was not run against a deployed stack. It includes a backend-replacement/persistence option; browser coverage is limited to app loading, title, cookies, and authenticated navigation, rather than full form interactions/mobile rendering.
- Live Discord registration, verification, direct messages, retry timing, and shutdown behavior were not tested with credentials. No outbound Discord messages were sent during implementation.
- Full clean dependency installation/container builds could not be exercised because shell DNS/network access is restricted. Actual artifact training, local builds, compilation, tests, and static SQL checks used available local dependencies.

Run the commands in the root README on a Docker/network-enabled host before considering production deployment verified. Ignored/blocked checks are not counted as passed.

## Independent final review

One fresh reviewer inspected the authored files, reference contracts, artifact checksum/dimensions, and parity fixture count. It found no Critical defects and two Important defects:

1. Weekly reports incorrectly used a rolling seven-day interval and omitted top expense categories. Fixed to Sunday 00:00 WIB through Saturday 20:00 WIB (exclusive), with top-three primary expense categories and net totals. Regression tests for fixed boundaries/report content were written before the correction and now pass. The new aggregation query also passed PostgreSQL preparation.
2. Nginx resolved the backend only at startup, risking persistent API 502 errors after backend-only replacement. Fixed with a shared upstream zone and Docker DNS re-resolution, supported by the pinned Nginx 1.28 image. The smoke script now optionally recreates the backend and verifies proxy recovery plus persisted balance/session data. Its live execution remains blocked.

Author contract inspection also corrected the friend search status from `none` to the reference `not_friend`; the live friendship test covers this value but is blocked with the other database tests.

## Rulings made during implementation

- Work in the fresh authorized workspace and preserve `app/.git`: root Git metadata is an environment mount, not a usable writable repository. File checkpoints replace commits. Repository metadata normalization remains separate; these files have not been committed to a root Git repository.
- Disable build-time Google font inlining: the network fetch blocked builds. Browser font loading remains; unavailable network uses existing font fallbacks.
- Initially pin the cached `furnace-rs` 1.0.0 release. Superseded by the 1.0.1 continuation above.
- Use native system libxcrypt bcrypt at cost 12 with a small serialized FFI boundary: the Rust bcrypt package was unavailable offline. Docker supplies `libcrypt1`; local builds need `libcrypt-dev`.
- Use Discord signed HTTP interactions rather than the reference Gateway connection: `/verify` and REST notifications stay in the main backend. This requires a public HTTPS interaction URL and Discord public-key configuration in the Developer Portal.

## Deferred minor review findings

- Full browser form/mobile UI regression coverage is pending. The supplied smoke is described as API smoke with limited browser checks, and its optional restart/persistence phase is also unexecuted here.
- HTTP's Discord interaction adapter directly references infrastructure configuration/signature verification rather than an application port. Domain/application remain independent of Furnace/SQL, but the HTTP crate has this extra adapter coupling.
- Feedback-augmented retraining records the base dataset hash and sample count but does not separately hash the feedback CSV. Preserve the exact feedback export alongside promoted artifacts until richer feedback provenance is added.
