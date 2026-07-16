# Instant Chat AI Coding Standards

> This file contains the highest-priority project rules for every AI coding agent working in this repository.
> It applies to code generation, edits, refactoring, tests, documentation, database migrations, Docker configuration, and release scripts.
> If a user's current instruction conflicts with this file, identify the conflict and wait for confirmation. Never bypass a rule silently.

## 1. Project Goal and Fixed Technology Stack

Instant Chat is a modern, native-feeling macOS instant messaging client.

The fixed technology stack is:

- Client: Flutter stable, Dart stable, and macOS desktop.
- Client state management: Riverpod.
- Client routing: go_router.
- Client networking: Dio and WebSocket.
- Client local storage: Drift and SQLite.
- Server: Go stable using a modular monolith architecture.
- Server interfaces: REST and WebSocket.
- Server database access: `database/sql` and sqlc.
- Database: MySQL 8.4 LTS with `utf8mb4`.
- Database migrations: golang-migrate or goose. The project may use only one.
- Infrastructure: Docker Compose, with Redis and MinIO enabled only when required.
- API contract: OpenAPI 3.x.

Without explicit user approval, an AI agent must not:

- Replace or add a competing state manager, router, ORM, database, or server framework.
- Split the modular monolith into microservices.
- Introduce GraphQL, gRPC, a message queue, Kubernetes, or a service mesh.
- Replace the Go server with Firebase, Supabase, or another managed backend.
- Allow the Flutter client to connect directly to MySQL, Redis, or an object storage administration interface.

## 2. Language and Locale

The repository language is American English (`en-US`).

- All user-facing copy must use natural American English.
- All documentation, code comments, test names, logs, errors, examples, and commit messages must use American English.
- Use American spelling, including `color`, `behavior`, `center`, `initialize`, and `license`.
- Source identifiers, API fields, and database identifiers must remain English.
- Do not add Chinese or other non-English copy unless the user explicitly approves localization work.
- User-provided content and localization test fixtures are exempt when they are required by a feature.
- API timestamps remain UTC RFC 3339 values regardless of display locale.

## 3. Instruction Priority

When instructions conflict, apply them in this order:

1. The user's explicit instruction for the current task.
2. This file and any closer-scoped `AGENTS.md` file.
3. Existing repository architecture, tests, and style.
4. Official language and framework conventions.

Do not replace an established project choice with a supposed industry best practice.

## 4. Required Preflight Checks

Before modifying any file:

1. Read the root `AGENTS.md` and every applicable nested `AGENTS.md` in full.
2. Check the working tree and identify uncommitted user changes.
3. Read the code, tests, configuration, and contracts directly related to the task.
4. Define the task boundary, inputs, outputs, and verifiable completion criteria.
5. Search for an existing implementation before creating a new one.
6. State assumptions that affect data, security, protocol compatibility, or releases.

If multiple interpretations would materially change the result, ask before choosing one. A small task may be executed immediately, but file inspection and verification are still mandatory.

## 5. Change Principles

Every change must be:

- Minimal: modify only what the current task requires.
- Traceable: every changed line must map to the user's request.
- Verifiable: changed behavior must have a test or repeatable validation method.
- Reversible: do not mix unrelated formatting, renaming, or cleanup into the task.
- Consistent: follow the existing project style and module boundaries.
- Simple: do not create abstractions or extension points for hypothetical future needs.

Do not:

- Modify unrelated code, comments, whitespace, or import order.
- Refactor neighboring code because it could look better.
- Combine a new architecture, new dependency, and broad refactor in one task.
- Add configuration or interfaces for speculative future requirements.
- Duplicate existing business logic.
- Deliver code that does not compile, migrate, or pass the applicable tests.

## 6. Change Authorization Matrix

### 6.1 Allowed Without Additional Approval

- Fix a clearly defined bug inside an existing module.
- Add or update tests for the current change.
- Update documentation directly related to current behavior.
- Add a backward-compatible field or internal implementation detail.
- Remove imports, variables, and functions made unused by the current change.

### 6.2 Requires Explicit User Approval

- Add a runtime dependency or Flutter plugin.
- Add a top-level repository directory.
- Change a public API, WebSocket event shape, or core database model.
- Change authentication, encryption, authorization, token, or secret storage behavior.
- Create a destructive migration or data backfill.
- Change the minimum macOS version, bundle identifier, signing, or sandbox entitlements.
- Change Docker ports, network topology, or volume strategy.
- Delete files, move modules, rename items in bulk, or reformat the repository broadly.
- Add a resident background process, launch-at-login behavior, automatic updates, or telemetry.
- Change CI/CD, release, signing, or notarization workflows.

### 6.3 Always Prohibited

- Commit keys, certificates, passwords, tokens, personal data, or a real `.env` file.
- Bypass tests, static analysis, security checks, or code signing.
- Use `git reset --hard`, force-push, or overwrite uncommitted user changes.
- Manually edit generated code, dependency lockfiles, or generated database files.
- Disable TLS validation, certificate validation, or macOS protections to make a feature work.
- Expose sensitive data in logs, errors, screenshots, or test fixtures.
- Invent cryptographic algorithms or describe an unaudited design as secure.

## 7. Required Directory Structure

Only the following top-level structure is allowed:

```text
Instant Chat/
├── AGENTS.md
├── Makefile
├── .editorconfig
├── .gitignore
├── .env.example
├── apps/
│   └── macos_client/
├── services/
│   └── api/
├── api/
│   └── openapi/
├── db/
│   ├── migrations/
│   ├── queries/
│   └── sqlc.yaml
├── deploy/
│   └── docker/
├── docs/
│   ├── AGENTS.md
│   └── README.md
├── scripts/
└── .github/
    └── workflows/
```

Rules:

- Do not place temporary scripts, database files, build artifacts, or debug output in the repository root.
- All Markdown documentation must live under `docs`, except the root `AGENTS.md` instruction entry point.
- Temporary files must use the operating system's temporary directory and must not be committed.
- Obtain approval before adding a top-level directory.
- Flutter code belongs only in `apps/macos_client`.
- Go server code belongs only in `services/api`.
- SQL migrations belong only in `db/migrations`.
- SQL query definitions belong only in `db/queries`.
- The REST contract source belongs in `api/openapi`.
- Docker and Compose files belong in `deploy/docker`. A service-specific Dockerfile may live beside that service if deployment configuration references it.
- Shared scripts belong in `scripts`. They must be noninteractive, repeatable, and return a nonzero status on failure.

## 8. File and Naming Standards

### General

- Use UTF-8 and LF line endings.
- Use meaningful names. Do not create names such as `util2`, `temp`, `data1`, or `new_manager`.
- Do not create unbounded junk drawers named `utils`, `common`, or `helpers`.
- Each file must have one clear responsibility.
- A handwritten source file should not exceed 300 lines. Split it or explain why it cannot be split before exceeding the limit.
- A function should not exceed 60 lines. Split complex branches and add tests.
- Comments explain why, not what the code already states.
- A TODO must include its reason and next action. Do not leave context-free TODO or FIXME comments.
- Generated files must carry their generator marker and may be updated only with the corresponding generation command.

### Dart and Flutter

- File names use `snake_case.dart`.
- Types, widgets, and enums use `UpperCamelCase`.
- Variables, methods, and providers use `lowerCamelCase`.
- Private members start with `_`.
- A page, feature, or reusable component gets its own file.

### Go

- Package names are short, lowercase, singular nouns without underscores.
- File names use lowercase `snake_case.go`.
- Every exported identifier requires useful GoDoc.
- Define interfaces at the point of use, not beside an implementation for hypothetical replacement.
- Do not create stacked names such as `GetUserServiceManagerImpl`.

### SQL

- Tables and columns use lowercase `snake_case`.
- Table names use the plural form consistently.
- Index names use `idx_<table>_<columns>`.
- Unique indexes use `uq_<table>_<columns>`.
- Foreign keys use `fk_<table>_<referenced_table>`.
- Migration file names contain an increasing version and a short action description.

## 9. Flutter Client Architecture

Organize Flutter code by feature:

```text
lib/
├── app/
├── core/
│   ├── config/
│   ├── network/
│   ├── storage/
│   ├── theme/
│   └── platform/
├── features/
│   ├── auth/
│   ├── contacts/
│   ├── conversations/
│   ├── messages/
│   └── settings/
└── main.dart
```

A feature may contain:

```text
feature/
├── data/
├── domain/
└── presentation/
```

Create only the layers a feature actually needs. Do not create empty directories or template filler.

Mandatory rules:

- Widgets must not access Dio, SQLite, Keychain, or WebSocket directly.
- Widgets must not contain database models, protocol parsing, or business rules.
- Providers orchestrate state but must not become a global service locator.
- Network DTOs, local database models, and domain models remain separate with explicit conversion.
- Every asynchronous state handles loading, success, empty data, and failure explicitly.
- Do not use `BuildContext` across an asynchronous gap without checking `mounted` again.
- Do not use `dynamic` to bypass type safety. Validate every JSON boundary.
- Do not use `print`. Use the project logging interface and never log sensitive data in release builds.
- Passwords, refresh tokens, and cryptographic keys belong only in macOS Keychain.
- SQLite stores only approved offline data, never plaintext passwords or server secrets.
- Every long-lived connection implements backoff, heartbeat, explicit close, and state recovery.
- Every outgoing message uses `client_message_id` for retry idempotency.
- Incremental synchronization uses the server-assigned conversation `sequence`, not the client's local clock.

## 10. macOS UI Standards

The interface must follow a restrained, native macOS visual language without compromising usability, performance, or accessibility.

- Colors, spacing, borders, corner radii, shadows, typography, and animation timing come from theme tokens.
- Do not scatter literal colors, font sizes, or dimensions throughout feature widgets.
- Body text and focus states must have sufficient contrast.
- Every interactive element supports keyboard focus, hover, pressed, and disabled states.
- System font scaling must not hide or clip essential content.
- Animations must be optional or respect the system Reduce Motion setting.
- Sound effects must be optional, nonblocking, and disabled in tests.
- Follow native macOS conventions for menus, shortcuts, window restoration, notifications, and Dock badges.
- Do not copy copyrighted icons, sounds, trademarks, or complete interfaces.

## 11. Go Server Architecture

Keep the server as a modular monolith organized by business capability:

```text
services/api/
├── cmd/api/
├── internal/
│   ├── auth/
│   ├── users/
│   ├── contacts/
│   ├── conversations/
│   ├── messages/
│   ├── realtime/
│   ├── notifications/
│   └── uploads/
└── go.mod
```

Mandatory rules:

- `cmd/api` handles dependency assembly, startup, and graceful shutdown only.
- An HTTP handler parses, validates, invokes a use case, and maps the response only.
- Business rules belong in the relevant module's service or use case.
- SQL access goes through a repository or sqlc-generated code.
- A module must not access another module's database implementation directly.
- Do not use mutable global state or an implicit service locator.
- Every I/O method takes `context.Context` as its first parameter.
- Every goroutine has an owner, an exit condition, and error handling.
- Preserve error context with `%w`. Do not compare errors by string.
- Do not ignore errors. If an error is intentionally discarded, explain why it is safe.
- Panic is limited to unrecoverable startup configuration errors, never routine business errors.
- Every service supports graceful shutdown and defines HTTP read, write, and idle timeouts.
- Database pool settings must be explicit and have reasonable defaults.
- Use structured logging and never log passwords, tokens, message bodies, or private user data.

## 12. REST and WebSocket Contracts

- REST paths start with `/api/v1`.
- JSON fields use `snake_case`.
- Time values use UTC RFC 3339 strings.
- JSON IDs use strings to avoid cross-language integer precision loss.
- Message history uses cursor pagination, not large offsets.
- Error responses contain a stable machine-readable code. Clients must not parse natural-language messages.

Error shape:

```json
{
  "error": {
    "code": "invalid_argument",
    "message": "A user-readable message",
    "request_id": "..."
  }
}
```

Every WebSocket event contains:

```json
{
  "event_id": "...",
  "type": "message.created",
  "version": 1,
  "occurred_at": "2026-01-01T00:00:00Z",
  "payload": {}
}
```

Rules:

- Once published, an event `type` and existing field must not change meaning.
- Adding fields must remain backward compatible. Removing, renaming, or changing a type requires a protocol version change.
- Clients ignore unknown optional fields but must not ignore unknown security-critical events.
- Shared REST and WebSocket models come from one contract source or have contract tests.
- An API change updates OpenAPI, examples, client models, and tests in the same task.

## 13. Database Standards

- Only the server may access the database.
- Every table uses InnoDB, `utf8mb4`, and an explicit collation.
- Store and process time in UTC.
- Never use floating point for money. Do not prebuild monetary fields when the project has no monetary requirement.
- Prefer database constraints for foreign keys, uniqueness, nullability, and data length.
- Parameterize every query. Never concatenate user input into SQL.
- Check index use for new queries and prevent unbounded table scans.
- Every list query has deterministic ordering and a limit.
- Message writes have an idempotency constraint, such as unique `client_message_id + sender_id`.
- A conversation `sequence` is unique and monotonic for reconnect synchronization.
- Migrations provide up and down operations. If down is unsafe, document that fact and obtain approval.
- Never modify a migration already merged or run in a shared environment. Add a corrective migration instead.
- Production application startup must not modify the database schema automatically.
- Destructive schema work follows an expand, migrate, switch, and contract sequence.
- A data backfill is repeatable, observable, rate-limited, and recoverable.

## 14. Security and Privacy

- All production network traffic uses TLS.
- Hash passwords with Argon2id or bcrypt using centralized parameters and an upgrade path.
- Access tokens are short-lived. Refresh tokens are revocable, rotated, and stored only as a digest or equivalent protected form.
- Rate-limit sign-in, registration, password reset, upload, and message sending.
- Enforce authorization on the server. Hiding client UI is not authorization.
- Confirm conversation membership before returning a conversation or message.
- Limit upload size, type, and count. Generate object keys on the server and never trust an original file name.
- Do not place uploaded content in an executable path.
- Use allowlists for CORS, redirects, callback URLs, and deep links.
- `.env.example` contains placeholders and instructions only, never usable credentials.
- End-to-end encryption is a separate architecture decision. Do not add a placeholder or false implementation without approval.

## 15. Docker and Configuration Standards

- Pin images to explicit versions. Never use `latest`.
- Build Go services with multiple stages and run the final image as a non-root user.
- Bind MySQL, Redis, and MinIO to localhost or an internal network by default.
- Store MySQL data in a named volume, never in the repository.
- Every long-running service defines a health check.
- Containers define an appropriate stop signal and graceful shutdown period.
- Inject passwords through environment variables or secret management, never an image or committed Compose file.
- Git ignores `.env`; only `.env.example` may be committed.
- Development, test, and production configuration remain distinct without manual file editing to switch environments.
- Docker Compose supports development and server deployment. It is not a macOS client runtime dependency.

## 16. Dependency Management

Before adding a dependency, explain:

1. Why the standard library and existing dependencies cannot solve the problem.
2. Its maintenance status, license, and macOS support.
3. Its effect on binary size, builds, permissions, and security surface.
4. Alternatives considered and the reason for the selection.

Rules:

- Do not add a runtime dependency without approval.
- Do not add a large utility package for one simple function.
- Do not retain dependencies with overlapping responsibilities.
- Commit lockfiles, but update them only through the official package manager.
- Dependency upgrades are isolated tasks, not side effects of feature work.
- A major upgrade requires migration notes and the full applicable test suite.

## 17. Testing Standards

Every behavior change requires a corresponding test update.

Minimum requirements:

- Bug fix: add a test that reproduces the failure before fixing it.
- Business rule: cover success, failure, boundaries, and authorization.
- API change: update handler and contract tests.
- SQL change: cover constraints, transactions, and migrations.
- WebSocket change: cover reconnects, duplicates, ordering, and catch-up behavior.
- Flutter state change: add provider or unit tests.
- Critical interaction change: add widget tests.
- Do not test only mock call counts. Verify the observable outcome.

Tests must:

- Be repeatable, parallel-safe, and independent of execution order.
- Avoid real third-party services and production data.
- Avoid dependence on a developer's home directory, time zone, or locale.
- Use a fixed or injectable clock for time logic.
- Fix random seeds or assert behavior that does not depend on a specific random value.

## 18. Formatting, Static Analysis, and Verification

Run the checks applicable to the change before delivery.

Flutter:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build macos --debug
```

Go:

```bash
gofmt -l .
go vet ./...
go test -race ./...
go build ./cmd/api
```

Docker and database:

```bash
docker compose config --quiet
docker compose build
```

Rules:

- Format only files changed by the task unless the user requests repository-wide formatting.
- Do not disable a lint, remove a test, or weaken an assertion to make a check pass.
- If a check cannot run, state the reason and risk in the final report.
- Fix failing checks. If a failure is unrelated, provide evidence and identify it clearly.

## 19. Git and Working Tree Protection

- Do not create a commit, tag, branch, or pull request unless the user explicitly requests it.
- Do not overwrite, stage, restore, or delete uncommitted user work.
- Do not use destructive Git commands.
- Do not modify unrelated lockfiles or generated files.
- Do not commit build artifacts, logs, coverage reports, database volumes, or editor caches.
- When the user requests a commit, use Conventional Commits and keep one logical change per commit.

## 20. Documentation Synchronization

Update documentation in the same task when:

- An environment variable changes: update `.env.example` and configuration instructions.
- An API changes: update OpenAPI and request or response examples.
- The database schema changes: add a migration and update model documentation.
- Startup behavior changes: update `docs/README.md`.
- Architecture boundaries change: update `docs/architecture.md` and explain the decision.
- User-visible behavior changes: update the relevant feature documentation or release notes.

Every documented command must be executable. Do not publish an unverified placeholder command.

## 21. AI Reporting Requirements

Before a complex task, briefly state:

- The interpreted requirement.
- The intended change scope.
- Verifiable completion criteria.
- Important assumptions or risks that need confirmation.

After a task, report:

- What changed.
- Which files changed.
- Which tests and checks ran and their results.
- Which checks did not run and why.
- Any migration, compatibility, security, or release concerns.

Do not:

- Claim that a test passed unless it actually ran.
- Hide failures, warnings, or uncertainty.
- Replace a clear result with a long process narrative.
- Leave unexplained temporary files or debug code.

## 22. Definition of Done

A task is complete only when all applicable statements are true:

- The implementation matches the request without extra features.
- The change respects directory and architecture boundaries.
- New behavior has proportionate tests.
- Formatting, static analysis, tests, and builds pass.
- Contracts, database changes, configuration, and documentation are synchronized.
- No secrets, debug output, temporary files, or unrelated changes remain.
- Compatibility, migration, and security effects are documented.
- The final report accurately describes validation results and remaining risks.

## 23. Required Final Self-Check

Before finishing, confirm:

- [ ] I changed only files required for the current task.
- [ ] I did not overwrite user work.
- [ ] I did not silently change the technology stack or architecture.
- [ ] I did not add an unapproved dependency or top-level directory.
- [ ] I did not expose a database credential or server secret to the client.
- [ ] I added or updated tests for behavior changes.
- [ ] I ran the applicable formatter, checks, tests, and build.
- [ ] I synchronized contracts, migrations, configuration, and documentation.
- [ ] I removed dead code and debug output created by my change.
- [ ] I reported results and unresolved risks accurately.
