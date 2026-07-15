# Instant Chat Architecture

## Current Boundaries

```text
Flutter macOS client
        |
        | HTTP /api/v1/health
        v
Go modular monolith
        |
        | database/sql
        v
MySQL 8.4
```

The Flutter client never accesses MySQL directly. Docker Compose manages local server infrastructure only; it is not a client runtime dependency.

The application locale and repository language are fixed to American English (`en-US`).

## macOS Client

The client is located in `apps/macos_client` and currently contains:

- `app`: application entry point and global theme assembly.
- `core/config`: compile-time API address configuration.
- `core/theme`: retro UI color, typography, and layout tokens.
- `features/system_status`: health domain model, Dio data access, Riverpod state, and presentation.

Widgets do not access Dio directly. The page observes a Riverpod provider, and the data layer validates the health response structure before passing it to the domain layer.

## Go API

The server is located in `services/api` and currently contains:

- `cmd/api`: dependency assembly, HTTP server, signal handling, and graceful shutdown.
- `internal/config`: environment variable loading and validation.
- `internal/health`: API and database health checks.

The API uses the standard library's `net/http` package. The MySQL `database/sql` driver is currently its only third-party server dependency.

## Health States

`GET /api/v1/health` returns one of two HTTP states:

- HTTP 200: the API and MySQL are both healthy.
- HTTP 503: the API is running, but MySQL is unavailable.

The complete response shape is defined in `api/openapi/openapi.yaml`. The client displays an unreachable network as `OFFLINE` and an HTTP 503 response as `DEGRADED`.

## Configuration

- Go reads its listening address and database DSN from environment variables.
- Flutter uses the compile-time `API_BASE_URL` variable to override its default API address.
- Docker Compose injects MySQL configuration from the root `.env` file.
- Passwords, tokens, certificates, and real `.env` files never enter Git.

## Not Yet Implemented

The project does not yet include sign-in, contacts, conversations, messages, WebSocket, local message caching, database migrations, Redis, MinIO, or end-to-end encryption. New capabilities must preserve the modular monolith boundary and update this document in the same change.
