# Instant Chat 架构

## 当前边界

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

Flutter 客户端不直接访问 MySQL。Docker Compose 只管理本地服务端基础设施，不是客户端运行依赖。

## macOS 客户端

客户端位于 `apps/macos_client`，当前包含：

- `app`：应用入口与全局主题装配。
- `core/config`：编译期 API 地址配置。
- `core/theme`：复古 UI 的颜色、字体和布局令牌。
- `features/system_status`：健康状态领域模型、Dio 数据访问、Riverpod 状态和页面。

Widget 不直接访问 Dio。页面只观察 Riverpod Provider，健康响应在数据边界完成结构校验后才进入领域层。

## Go API

服务端位于 `services/api`，当前包含：

- `cmd/api`：依赖装配、HTTP Server、信号处理和优雅关闭。
- `internal/config`：环境变量加载与校验。
- `internal/health`：API 和数据库健康检查。

API 使用标准库 `net/http`。除 MySQL `database/sql` 驱动外，当前没有引入服务端框架。

## 健康状态

`GET /api/v1/health` 返回两种状态：

- HTTP 200：API 与 MySQL 均正常。
- HTTP 503：API 正常运行，但 MySQL 不可用。

完整响应结构由 `api/openapi/openapi.yaml` 定义。客户端将网络不可达显示为 `OFFLINE`，将 HTTP 503 显示为 `DEGRADED`。

## 配置

- Go 从环境变量读取监听地址和数据库 DSN。
- Flutter 通过 `API_BASE_URL` 编译期变量覆盖默认 API 地址。
- Docker Compose 从根目录 `.env` 注入 MySQL 配置。
- 密码、Token、证书和真实 `.env` 不进入 Git。

## 暂未实现

当前没有登录、联系人、会话、消息、WebSocket、本地消息缓存、数据库迁移、Redis、MinIO 或端到端加密。新增能力时必须保持模块化单体边界，并同步更新本文档。
