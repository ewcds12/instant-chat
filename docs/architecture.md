# Instant Chat Architecture

## Current Boundaries

```text
Flutter macOS client
        |
        | HTTP APIs + authenticated WebSocket /api/v1/realtime
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
- `core/platform`: macOS-specific platform adapters, including the native image file picker.
- `core/theme`: native macOS UI color, typography, and layout tokens.
- `features/auth`: authentication domain contracts, Dio and Keychain adapters, Riverpod session state, and forms.
- `features/users`: the public account identity shared by contacts and direct conversations.
- `features/contacts`: exact username search, contact-request workflows, accepted contacts, and Riverpod state.
- `features/conversations`: direct-conversation creation, persisted unread-count state, realtime list updates, and channel selection.
- `features/messages`: message history, text, image, and file REST sending, realtime reconciliation, idempotent retry state, and channel presentation.
- `features/realtime`: authenticated WebSocket lifecycle, heartbeat, reconnect backoff, and event parsing.
- `features/system_status`: health domain model, Dio data access, Riverpod state, and presentation.

Widgets do not access Dio or Keychain directly. Presentation observes Riverpod providers, while data adapters validate remote and stored JSON before passing domain objects upward.

The client keeps the complete session in macOS Keychain. On startup it validates an unexpired access token, rotates an expired access token with the refresh token, or returns to sign-in when the refresh token is rejected. While signed in, the auth controller refreshes the access token shortly before expiry, writes the rotated session back to Keychain, and falls back to sign-in when the refresh token is rejected. A network failure preserves a locally valid session so sign-out remains available offline.

The authenticated shell exposes conversations, contacts, requests, and system status as keyboard-focusable Material navigation destinations. Contact and conversation providers are automatically disposed when the authenticated shell is removed so one account's in-memory directory state cannot appear in another account's session.

## Go API

The server is located in `services/api` and currently contains:

- `cmd/api`: dependency assembly, HTTP server, signal handling, and graceful shutdown.
- `internal/auth`: registration, authentication, opaque token issuance and rotation, HTTP handlers, and MySQL persistence.
- `internal/users`: shared username normalization rules.
- `internal/contacts`: exact account search, pending and accepted relationship rules, HTTP handlers, and MySQL persistence.
- `internal/conversations`: authorized direct-conversation creation, membership transactions, list handlers, and MySQL persistence.
- `internal/messages`: text, image, and file validation, idempotent REST sending, cursor history, membership authorization, and MySQL persistence.
- `internal/realtime`: authenticated WebSocket connections, member-targeted delivery, heartbeat, and graceful shutdown.
- `internal/config`: environment variable loading and validation.
- `internal/health`: API and database health checks.
- `internal/httpapi`: bounded JSON handling, stable errors, request IDs, and IP rate limiting.
- `internal/store`: sqlc-generated database access code; generated files must not be edited manually.

The API uses the standard library's `net/http` package and the zero-dependency ISC-licensed `github.com/coder/websocket` package for RFC 6455 framing. MySQL access stays behind repository interfaces and sqlc-generated queries.

## Authentication

Passwords are hashed with Argon2id using one centralized configuration. Account registration and login use the username as the credential identifier and do not require email addresses. Login failures do not reveal whether an account exists, and registration and login are limited to 10 attempts per IP address per minute in each API process.

Access tokens are cryptographically random opaque values valid for 15 minutes. Refresh tokens are cryptographically random opaque values valid for 30 days and are rotated in a database transaction. MySQL stores only SHA-256 token digests, never the bearer values returned to the client.

The authentication tables and changes are owned by `db/migrations`. Source queries are owned by `db/queries`, and `db/sqlc.yaml` generates the server store package.

## Contacts

Usernames are normalized to lowercase and contain 3 to 32 ASCII letters, numbers, or underscores, starting with a letter. Exact username search returns only public identity fields.

One `contact_relationships` row represents both directions of a user pair. The lower and higher user IDs have a unique constraint, which prevents duplicate or opposing requests. The requester is retained while the relationship is pending. Acceptance changes the row to `accepted`; rejection and contact removal delete the row so a future request can be sent.

## Conversations

A direct conversation requires an accepted contact relationship when it is created. The ordered user pair is unique at the database layer, so repeated or concurrent create requests return the same conversation. Conversation creation and both membership inserts occur in one transaction.

The conversation list contains direct-conversation identity, peer information, and a member-specific unread count. Each membership stores the largest viewed message sequence. A read marker can only advance and is clamped to the latest persisted sequence, so a client cannot mark future messages as read. The macOS client updates the list from realtime message events, increments unread counts for incoming messages, and records the active channel's latest sequence as read.

## Messages

Each message carries a 32-character, client-generated hexadecimal ID. A unique database constraint on the conversation, sender, and client ID makes retries idempotent. The first successful send returns HTTP 201; a retry with the same ID returns the existing message with HTTP 200.

Each conversation owns a monotonically increasing sequence. Sending locks the conversation row, allocates its next sequence, creates the message, advances the sequence, and updates the conversation timestamp in one transaction. A unique conversation-and-sequence constraint protects the ordering invariant.

History is returned in ascending sequence order, at most 100 messages per request. The optional `before` cursor requests older sequences. The mutually exclusive `after` cursor requests newer sequences for reconnect recovery. `next_cursor` continues in the requested direction and is null when that direction is complete. Send and history endpoints return the same not-found response when the conversation is missing or the user is not a member. Message sending is limited to 60 attempts per IP address per minute in each API process.

Messages have a `kind` of `text`, `image`, or `file`. Text messages store a validated body. Image messages store one PNG, JPEG, GIF, or WebP attachment up to 15 MB in MySQL for the first implementation. File messages store one named file attachment up to 25 MB in MySQL. Attachment bytes are returned only through authenticated API endpoints that verify the requester is a member of the attachment's conversation. The client uses native macOS file pickers for selecting images and files and sends uploads through the API, never by connecting directly to storage.

After a new message commits, the realtime hub looks up the conversation members and sends a versioned `message.created` event to every connected window for those users. A failed realtime lookup or disconnected client does not change the successful REST result because persisted history remains the source of truth.

The macOS client opens one authenticated WebSocket per signed-in session, sends heartbeat pings, reconnects with bounded exponential backoff, replaces the connection after session rotation, and closes the connection on sign-out. Active channels merge REST responses and realtime events by sender and client message ID, sort by server sequence, and request every sequence after the latest local message when a channel opens, the connection is restored, an incoming event exposes a sequence gap, or the two-second active-channel fallback check runs. Synchronization requests never overlap, and all recovery paths use the same idempotent reconciliation.

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

The project does not yet include local message caching, cross-user read receipts, Redis, MinIO, password reset, social sign-in, large-file object storage, or end-to-end encryption. New capabilities must preserve the modular monolith boundary and update this document in the same change.
