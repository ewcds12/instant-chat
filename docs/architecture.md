# Instant Chat Architecture

## Current Boundaries

```text
Flutter macOS client
        |
        | HTTP /api/v1/health and /api/v1/auth/*
        v
Go modular monolith
        |
        | database/sql + sqlc
        v
MySQL 8.4
```

The Flutter client never accesses MySQL directly. Docker Compose manages local server infrastructure only; it is not a client runtime dependency.

The application locale and repository language are fixed to American English (`en-US`).

## macOS Client

The client is located in `apps/macos_client` and currently contains:

- `app`: application entry point and global theme assembly.
- `core/config`: compile-time API address configuration.
- `core/network`: shared Dio lifecycle and connection configuration.
- `core/theme`: retro UI color, typography, and layout tokens.
- `features/auth`: authentication domain contracts, Dio and Keychain adapters, Riverpod session state, and forms.
- `features/system_status`: health domain model, Dio data access, Riverpod state, and presentation.

Widgets do not access Dio or Keychain directly. Presentation observes Riverpod providers, while data adapters validate remote and stored JSON before passing domain objects upward.

The client keeps the complete session in macOS Keychain. On startup it validates an unexpired access token, rotates an expired access token with the refresh token, or returns to sign-in when the refresh token is rejected. A network failure preserves a locally valid session so sign-out remains available offline.

## Go API

The server is located in `services/api` and currently contains:

- `cmd/api`: dependency assembly, HTTP server, signal handling, and graceful shutdown.
- `internal/auth`: registration, authentication, opaque token issuance and rotation, HTTP handlers, and MySQL persistence.
- `internal/config`: environment variable loading and validation.
- `internal/health`: API and database health checks.
- `internal/httpapi`: bounded JSON handling, stable errors, request IDs, and IP rate limiting.
- `internal/store`: sqlc-generated database access code; generated files must not be edited manually.

The API uses the standard library's `net/http` package. MySQL access stays behind repository interfaces and sqlc-generated queries.

## Authentication

Passwords are hashed with Argon2id using one centralized configuration. Login failures do not reveal whether an account exists, and registration and login are limited to 10 attempts per IP address per minute in each API process.

Access tokens are cryptographically random opaque values valid for 15 minutes. Refresh tokens are cryptographically random opaque values valid for 30 days and are rotated in a database transaction. MySQL stores only SHA-256 token digests, never the bearer values returned to the client.

The authentication tables and changes are owned by `db/migrations`. Source queries are owned by `db/queries`, and `db/sqlc.yaml` generates the server store package.

## Health States

`GET /api/v1/health` returns one of two HTTP states:

- HTTP 200: the API and MySQL are both healthy.
- HTTP 503: the API is running, but MySQL is unavailable.

The complete response shape is defined in `api/openapi/openapi.yaml`. The client displays an unreachable network as `OFFLINE` and an HTTP 503 response as `DEGRADED`.

## Configuration

- Go reads its listening address and database DSN from environment variables.
- Flutter uses the compile-time `API_BASE_URL` variable to override its default API address.
- Docker Compose injects MySQL configuration from the root `.env` file.
- golang-migrate reads its MySQL URL from `MIGRATION_DATABASE_URL`.
- Passwords, tokens, certificates, and real `.env` files never enter Git.

## Not Yet Implemented

The project does not yet include contacts, conversations, messages, WebSocket, local message caching, Redis, MinIO, password reset, email verification, social sign-in, or end-to-end encryption. New capabilities must preserve the modular monolith boundary and update this document in the same change.
