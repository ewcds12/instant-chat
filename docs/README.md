# Instant Chat

Instant Chat 是一个使用复古界面设计的 macOS 即时通讯客户端项目。

## 当前状态

最小全链路已经建立：

- Flutter macOS 客户端显示 API 与数据库连接状态。
- Go API 提供 `GET /api/v1/health`。
- 健康检查通过 MySQL `PingContext` 验证数据库连接。
- Docker Compose 提供固定版本的 MySQL 8.4 开发环境。
- OpenAPI 描述健康检查的成功与降级响应。

登录、联系人、消息、WebSocket、Drift、Redis 和文件上传尚未实现。

## 技术栈

- macOS 客户端：Flutter、Dart、Riverpod 和 Dio。
- 服务端：Go、REST 和 `database/sql`。
- 数据库：MySQL 8.4 LTS。
- 本地基础设施：Docker Compose。
- 接口契约：OpenAPI 3.1。

后续功能按需引入 go_router、WebSocket、Drift、SQLite、sqlc、Redis 和 MinIO。

## 环境要求

- Flutter stable 3.44 或兼容版本。
- Go 1.26 或兼容版本。
- Docker Engine 与 Docker Compose v2。
- Xcode 及 macOS 桌面开发工具。

如果开发机设置了 HTTP 代理，请确保 `NO_PROXY` 至少包含 `localhost,127.0.0.1,::1`，否则 Flutter 测试进程可能无法连接本地 WebSocket。

## 本地配置

在仓库根目录创建本地环境文件：

```bash
cp .env.example .env
```

启动前必须修改 `.env` 中的示例密码。`.env` 已被 Git 忽略，不得提交真实凭据。

## 启动 MySQL

在仓库根目录运行：

```bash
docker compose --env-file .env -f deploy/docker/compose.yaml up -d mysql
```

查看状态：

```bash
docker compose --env-file .env -f deploy/docker/compose.yaml ps
```

## 启动 Go API

在仓库根目录运行：

```bash
set -a
source .env
set +a
cd services/api
go run ./cmd/api
```

API 默认监听 `http://127.0.0.1:8080`。健康检查地址：

```text
http://127.0.0.1:8080/api/v1/health
```

## 启动 macOS 客户端

打开另一个终端窗口：

```bash
cd apps/macos_client
flutter run -d macos
```

客户端默认连接 `http://127.0.0.1:8080`。如需覆盖地址：

```bash
flutter run -d macos --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

## 验证

Go：

```bash
cd services/api
gofmt -l .
go vet ./...
go test -race ./...
go build -o /tmp/instant-chat-api ./cmd/api
```

Flutter：

```bash
cd apps/macos_client
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build macos --debug
```

## 项目规范

所有 AI 编码代理必须先读取根目录 `AGENTS.md`，再完整读取 `docs/AGENTS.md`。

架构边界记录在 `docs/architecture.md`，REST 契约位于 `api/openapi/openapi.yaml`。

## 下一里程碑

实现注册与登录，包括服务端鉴权、数据库迁移、客户端表单和 macOS Keychain Token 存储。
