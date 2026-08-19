# Instant Chat

Instant Chat is a macOS instant messaging client with a modern, native-feeling interface.

The repository uses American English (`en-US`). The product interface supports
English, Japanese, and Simplified Chinese; user-authored messages, posts,
comments, and remote news content are never translated automatically.

## Current Status

The authentication, contacts, direct conversations, and persisted message foundations are in place:

- The Flutter macOS client opens registration and sign-in in a compact, fixed-size authentication window, then expands the same native window into the resizable chat workspace after authentication succeeds.
- Registration uses a unique lowercase username and password, with no email address required.
- The client restores sessions from macOS Keychain and refreshes access tokens before they expire.
- The authenticated client provides modern Chats, Contacts, Explore, and system-status workspaces.
- General settings can switch the complete app-owned interface between English, Japanese, and Simplified Chinese. The choice is stored on macOS, updates the main and standalone Settings windows immediately, and is restored the next time Instant Chat opens. User messages, posts, comments, filenames, account names, and Daily Brief content remain unchanged; native file selection and download prompts follow the selected interface language.
- The standalone Settings window can register or unregister the installed macOS app as a login item, persist whether links use the default browser, show or hide the app in the Dock, and choose whether closing the authenticated chat window keeps Instant Chat running or quits the app. These preferences restore on startup, and Launch at login directs users to System Settings when macOS requires approval. Local ad-hoc development builds report Launch at login as unavailable until the app is installed as a signed build.
- The account card opens an in-app Profile sheet where users can set a profile photo, Name, Gender, Region, and ID. Changes persist to MySQL, are restored with the session, and update connected peers through the authenticated realtime channel.
- The chat workspace provides real conversation filtering, last-message previews for text, photo, and file messages, automatic older-history loading while scrolling, a focused complete-history search with direct result navigation, an inline Contact Info view with back navigation, and a persistent desktop master-detail layout.
- Message rows omit sender avatars so incoming and outgoing content align cleanly with the chat area edges.
- The authentication window opens at 420 by 500 points. The authenticated chat window expands to 1,150 by 750 points and remains resizable down to 960 by 620 points.
- The Contacts workspace provides an alphabetical directory with private contact remarks searchable alongside original names and IDs, exact ID lookup for new people, an inline friend-request drawer, a selected-contact detail panel with an enlarged and downloadable profile-photo preview, real shared photos, files, and web links, complete-history message search with direct navigation and a three-second highlight on the matching chat message, safe removal confirmation, and direct-message navigation.
- Explore provides a focused global feed visible to every Instant Chat account. Users can publish up to 1,000 characters and four photos, expand or collapse long post text without nested scrolling, navigate and download photos through the same enlarged viewer used by Chats, scroll through cursor-paginated posts, delete their own posts, and report another user's post. Each post also opens into a compact detail view with cursor-paginated text comments, a single shared scroll area, a fixed one-to-three-line composer, and owner-only comment deletion. Wide windows also show a compact Daily Brief sourced from Wikipedia Current Events; headlines open their source pages in the default browser and the brief disappears on narrow layouts.
- Incoming friend requests show a notification dot beside Contacts, appear below the Contacts search field, and can be expanded, accepted, or declined without leaving the workspace. The dot clears when no incoming requests remain, and accepting a request immediately adds the shared direct conversation to both users' Chats lists.
- Direct channels load cursor-paginated history, receive realtime messages, automatically recover sequence gaps on opening, reconnecting, detecting an out-of-order event, or through a two-second active-channel fallback check, show persisted unread counts, mark viewed messages as read, update conversation-card previews in realtime with the same reconnect and two-second recovery safeguards, and can send or retry text, image, and file messages without creating duplicates.
- Text messages underline `http` and `https` links. General settings persist whether links open in the default macOS browser or a lightweight Instant Chat browser window, and the same preference applies to shared contact links and Daily Brief sources.
- Message context menus support replying to text, photo, or file messages. The composer shows a cancellable preview, retries retain the reply target, and sent replies include a persisted summary in history and realtime updates. Clicking a reply summary loads older history when needed, opens the original message, and highlights it for three seconds.
- Text-message context menus provide on-device translation into every target language reported by the current Mac, with English, English (UK), Simplified Chinese, Traditional Chinese, Japanese, Spanish, French, and Korean available as fallbacks when the system language query is unavailable. The selected target language and completed translations persist locally, translated text appears below the unchanged original message after refresh or reopening the chat, and choosing Original from the message menu restores the original bubble and clears its stored translation.
- Image messages support PNG, JPEG, GIF, and WebP files up to 15 MB. Image bytes are stored behind authenticated API endpoints and are available only to conversation members; the macOS image preview can save the current image through the native Save dialog.
- The macOS composer accepts an image from the system clipboard, stages one rounded preview with a remove control, and can send the staged image followed by the typed text from one send action.
- The active macOS chat accepts files dragged from Finder, shows a drop target before release, and sends supported images and regular files in drop order while rejecting folders and oversized attachments locally.
- File messages support files up to 2 GB. New file bytes stream through the authenticated API into a private MinIO bucket, while MySQL stores metadata and remains backward compatible with existing database-backed files.
- The Go API provides health, registration, sign-in, refresh, sign-out, current-user, profile update, and authenticated avatar endpoints.
- The Go API enforces unique bilateral contact relationships and unique direct conversations.
- The health check verifies the MySQL connection with `PingContext`.
- MySQL migrations and sqlc queries define users, opaque session tokens, contact relationships, conversations, members, ordered messages, public posts, persistent post likes, single-level threaded post comments, and reports.
- Docker Compose provides pinned MySQL 8.4 and source-built MinIO development services.
- OpenAPI defines the implemented HTTP and WebSocket event contracts.

Local Drift storage, cross-user read receipts, Redis, and end-to-end encryption have not been implemented.

The local MinIO image builds the pinned `RELEASE.2025-10-15T17-29-55Z` source under AGPLv3. The upstream MinIO server repository is archived, so a production deployment must complete its own licensing, maintenance, and support review. The Go application uses the separately maintained Apache-2.0 `minio-go` client.

## Technology Stack

- macOS client: Flutter, Dart, Riverpod, Dio, and macOS Keychain.
- Server: Go, REST, WebSocket, `database/sql`, and sqlc.
- Database: MySQL 8.4 LTS.
- Local infrastructure: Docker Compose.
- API contract: OpenAPI 3.1.
- Database migrations: golang-migrate.

Future features will add go_router, Drift, SQLite, and Redis only when they are needed.

## Requirements

- Flutter stable 3.44 or a compatible version.
- Go 1.26 or a compatible version.
- Docker Engine and Docker Compose v2.
- Xcode with the macOS desktop development tools.

If the development machine uses an HTTP proxy, make sure `NO_PROXY` includes at least `localhost,127.0.0.1,::1`. Otherwise, the Flutter test process may be unable to connect to its local WebSocket.

## Local Configuration

Create the local environment file from the repository root:

```bash
cp .env.example .env
```

Replace the example passwords in `.env` before starting the services. Git ignores `.env`; never commit real credentials.

## Start Development

Start the complete development environment from the repository root:

```bash
make dev
```

This command starts MySQL and MinIO, waits for both health checks, applies pending migrations, builds and starts the Go API, and opens the Flutter macOS client. Close the client or press `Ctrl+C` to stop the API. The Docker services stay available for faster restarts.

The local Debug client uses ad-hoc signing and the system Keychain, so `make dev` does not require an Apple Development certificate, team, or provisioning profile. Release builds keep the configured macOS signing and data-protection Keychain behavior.

The first MinIO startup builds its pinned server source and can take several minutes. Docker reuses the completed image for subsequent starts.

Stop MySQL, MinIO, and the Docker development network when they are no longer needed:

```bash
make stop
```

Other development commands:

```bash
make migrate
make check
```

`make migrate` applies pending migrations. `make check` validates Docker Compose and SQL sources, then runs Go formatting checks, vet, race tests, the Go build, Dart formatting checks, Flutter analysis, Flutter tests, and the macOS debug build.

## Manual Startup and Troubleshooting

Start MySQL and MinIO:

```bash
docker compose --env-file .env -f deploy/docker/compose.yaml up -d mysql minio
```

Apply migrations with the pinned tool version:

```bash
./scripts/migrate.sh
```

Run this step after MySQL is healthy and before starting the API. The API also requires a healthy MinIO service and creates its private bucket on startup. Migration filenames are append-only after they reach a shared branch.

Start the API:

```bash
set -a
source .env
set +a
cd services/api
go run ./cmd/api
```

The API listens on `http://127.0.0.1:8080` by default. Implemented endpoints are:

```text
GET  /api/v1/health
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
GET  /api/v1/auth/me
PATCH /api/v1/auth/me
PUT  /api/v1/auth/me/avatar
GET  /api/v1/users/{user_id}/avatar
GET  /api/v1/users/search?username={username}
POST /api/v1/contact-requests
GET  /api/v1/contact-requests
POST /api/v1/contact-requests/{request_id}/accept
POST /api/v1/contact-requests/{request_id}/reject
POST /api/v1/contact-requests/{request_id}/cancel
GET  /api/v1/contacts
DELETE /api/v1/contacts/{user_id}
POST /api/v1/conversations
GET  /api/v1/conversations
POST /api/v1/conversations/{conversation_id}/read
POST /api/v1/conversations/{conversation_id}/messages
POST /api/v1/conversations/{conversation_id}/messages/images
POST /api/v1/conversations/{conversation_id}/messages/files
GET  /api/v1/conversations/{conversation_id}/messages?before={sequence}&limit={count}
GET  /api/v1/conversations/{conversation_id}/messages?after={sequence}&limit={count}
GET  /api/v1/message-images/{image_id}
GET  /api/v1/message-files/{file_id}
GET  /api/v1/posts?before={post_id}&limit={count}
GET  /api/v1/news/daily
POST /api/v1/posts
DELETE /api/v1/posts/{post_id}
GET  /api/v1/posts/{post_id}/comments?before={comment_id}&limit={count}
POST /api/v1/posts/{post_id}/comments
DELETE /api/v1/posts/{post_id}/comments/{comment_id}
POST /api/v1/posts/{post_id}/reports
GET  /api/v1/post-images/{image_id}
GET  /api/v1/realtime  (WebSocket upgrade)
```

Start the client in another terminal:

```bash
cd apps/macos_client
flutter run -d macos
```

The client connects to `http://127.0.0.1:8080` by default. Override the address when needed:

```bash
flutter run -d macos --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

## Verification

```bash
make check
```

## Project Standards

Every AI coding agent must read the root `AGENTS.md` and then read `docs/AGENTS.md` in full.

Architecture boundaries are documented in `docs/architecture.md`. The REST contract is located at `api/openapi/openapi.yaml`.

## Next Milestone

Add local Drift caching on top of the persisted REST and WebSocket message source of truth.
