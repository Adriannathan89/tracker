# Tracker Android Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a full Android Flutter client matching Tracker's current web UI and API.

**Architecture:** Typed models and injectable HTTP/session adapters feed one shared controller. Feature screens compose a common visual theme and widgets; existing backend contracts remain authoritative.

**Tech Stack:** Flutter 3.35.7/Dart, native HttpClient, flutter_secure_storage, intl, url_launcher, Android Kotlin/Gradle.

**Spec:** `docs/superpowers/specs/2026-10-09-tracker-android-design.md`

## Global Constraints

- Default API `https://tracker.adrianportofolio.my.id/api/`; Flutter in `mobile/`.
- Application ID `my.id.adrianportofolio.tracker`, label Tracker, min SDK 24.
- Existing API cookies, Indonesian copy, current cream/lime/dark design.
- No passwords or keystores committed; no backend/model duplication.

## Review Focus

- Expired access cookie and simultaneous 401 responses share one refresh.
- Network failures retain sessions and show retry; writes do not replay after timeout.
- Drafts never affect committed totals; category changes select a valid secondary.
- Repayment is available only to the debtor; incoming requests only to receiver.
- Small screens, large text, keyboard and empty results remain usable.

### Task 1: Android scaffold and API/session layer

Files: `mobile/pubspec.yaml`, `mobile/android/`, `mobile/lib/core/`, `mobile/test/api_client_test.dart`, `mobile/test/models_test.dart`.

- [x] Write contract tests for expiration, refresh concurrency, network failure, logout, DTO amounts/categories and filtering.
- [x] Attempt Flutter tests and record available-tool limitations.
- [x] Implement AppConfig, SessionStore, ApiTransport/ApiClient and typed models.
- [ ] Verify tests when SDK is available; otherwise run native static checks and keep runtime validation outstanding.

### Task 2: Shared controller and visual application

Files: `mobile/lib/app.dart`, `mobile/lib/core/app_controller.dart`, `mobile/lib/ui/`, `mobile/lib/features/`, `mobile/test/app_test.dart`.

- [x] Write login, navigation, record creation/confirmation, friend/debt and profile flow tests.
- [x] Implement coherent state, full feature screens, theme, reusable cards and async/error states.
- [x] Check API route/payload coverage against the backend controllers and mobile web source.
- [x] Review asynchronous disposal, stale session responses, validation and small-screen layout in source; device validation remains outstanding.

### Task 3: APK build and documentation

Files: `.github/workflows/android.yml`, `mobile/tool/build-apk.sh`, `mobile/README.md`, root ignores/README.

- [x] Provide local build and manual CI artifact workflow with analysis and tests before APK.
- [x] Document configuration, signing, installation and actual verification limitations.
- [x] Run available static checks, inspect the diff and obtain a final code review.

## Execution record

- Direct implementation preserved from the user's session instructions; work in the existing shared workspace.
- Preflight: no Flutter, Dart or Android SDK found; terminal download fails DNS resolution. Flutter test/build execution remains unavailable locally; source tests and CI will be supplied.
- Source delivered: full API/client/controller/screens, Android host, local script, CI and documentation. Static XML/YAML/shell/delimiter checks pass. Independent review found no remaining Critical/Important issues in reviewed source; fixed stale reload ordering, disposed input access and offscreen test actions. This is not a compiled or device-tested release.
- Remaining verification: `flutter pub get`, `flutter analyze`, `flutter test`, Android Gradle/APK build and live backend/device flows. Dependency lock must be committed after successful resolution; no fabricated lock or APK was added.
