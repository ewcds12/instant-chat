# Instant Chat

Instant Chat 是一个使用复古界面设计的 macOS 即时通讯客户端项目。

## 项目状态

仓库目前处于基础设施初始化阶段，尚未生成 Flutter 客户端、Go 服务端或数据库迁移。

## 固定技术栈

- macOS 客户端：Flutter、Dart、Riverpod、go_router、Dio、WebSocket、Drift 和 SQLite。
- 服务端：Go、REST、WebSocket、`database/sql` 和 sqlc。
- 数据库：MySQL 8.4 LTS。
- 开发与部署：Docker Compose。
- 后续可选组件：Redis 和 MinIO。

## 目标目录

```text
Instant Chat/
├── apps/macos_client/
├── services/api/
├── api/openapi/
├── db/migrations/
├── db/queries/
├── deploy/docker/
├── docs/
└── scripts/
```

目录仅在对应功能开始实现时创建，不保留无内容的占位目录。

## 配置约定

- 本地配置从根目录 `.env.example` 复制生成 `.env`。
- `.env`、证书、密钥和其他真实凭据不得提交到 Git。
- 客户端不得直接连接 MySQL、Redis 或对象存储管理接口。
- Docker Compose 仅用于开发与服务端部署，不是 macOS 客户端的运行依赖。

## AI 编码规范

所有 AI 编码代理必须先读取根目录 `AGENTS.md`，再完整读取 `docs/AGENTS.md`。

## 下一里程碑

建立可运行的最小全链路：

1. 创建 Flutter macOS 客户端并显示基础复古欢迎界面。
2. 创建 Go API 并提供 `/api/v1/health`。
3. 创建包含 MySQL 健康检查和持久卷的 Docker Compose 配置。
4. 让客户端请求健康检查并展示服务连接状态。
