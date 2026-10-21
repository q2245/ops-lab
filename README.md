# Ops Lab 运维学习实验室

这是一套本地运维学习环境，覆盖 Linux / 网络、可观测性、中间件、K8s、CI/CD 的完整练习路径。所有东西跑在 Docker Compose 和 kind 上，按需启动，不占资源。

## 环境要求

- macOS + OrbStack（或 Docker Desktop）
- Docker Compose v2
- kind（可选，用于 K8s 部分）：`brew install kind`

## 目录结构

```text
ops-lab/
├── compose/          Docker Compose 及各组件配置
├── k8s/              kind 集群配置与 K8s manifests
├── demos/            演示应用（暴露指标/日志/trace）
├── scripts/          启动、压测、K8s 管理脚本
├── docs/             分主题学习文档
└── Makefile          快捷命令
```

## 快速开始

### 1. 起可观测性栈（Prometheus + Grafana + Loki + 演示应用）

```bash
cd ops-lab
make up PROFILE=core
```

启动后访问：

| 服务 | 地址 | 账号 |
|------|------|------|
| Grafana | <http://localhost:3000> | admin / admin |
| Prometheus | <http://localhost:9090> | 无 |
| Alertmanager | <http://localhost:9093> | 无 |
| 演示应用 | <http://localhost:8081> | 无 |

### 2. 制造一些流量，让图表动起来

```bash
curl http://localhost:8081/          # 正常请求
curl http://localhost:8081/slow      # 慢请求，看 P95 抬升
curl http://localhost:8081/error     # 500 错误，触发告警规则
```

或者压测：

```bash
make stress
```

### 3. 加日志组件（Loki + Alloy）

`core` profile 已包含 Loki，Alloy 会自动采集所有容器的 stdout/stderr。在 Grafana 的 Explore 里选 Loki，用这个查询找演示应用的日志：

```logql
{container="demo-app"}
```

### 4. 加链路追踪（Jaeger + OTel Collector）

```bash
make up PROFILE=tracing
```

然后访问 <http://localhost:16686>，选择 `demo-app` 服务，点 Find Traces。

### 5. 中间件（按需启动）

```bash
make up PROFILE=redis         # Redis 单机
make up PROFILE=redis-ha      # 一主两从 + 三哨兵
make up PROFILE=redis-cluster # 三主三从 Cluster
make up PROFILE=db            # MySQL + PostgreSQL
make up PROFILE=mq            # Kafka + RabbitMQ
```

### 6. 负载均衡

```bash
make up PROFILE=lb
curl http://localhost:8080/      # Nginx 转发
curl http://localhost/           # HAProxy 转发
```

HAProxy 状态页：<http://localhost:8404/stats>

### 7. K8s（kind 多节点）

```bash
brew install kind
make k8s             # 创建 1 控制面 + 2 工作节点，并部署演示应用
make k8s-delete      # 删除
```

创建后访问 <http://localhost:30080>，或用 `kubectl -n ops-lab get pods` 查看。

## 学习路线

按 `docs/` 里的顺序看，每个主题都配有对应的动手任务：

1. [Linux 与网络](docs/01-linux-network.md)
2. [可观测性：指标、日志、链路](docs/02-observability.md)
3. [中间件](docs/03-middleware.md)
4. [Kubernetes](docs/04-k8s.md)
5. [CI/CD](docs/05-cicd.md)
6. [完整学习路线图](docs/roadmap.md)

## 常用命令

```bash
make ps PROFILE=core     # 看状态
make logs PROFILE=core   # 看日志
make down PROFILE=core   # 停止
make clean               # 全部清理（含数据卷）
```

## 注意事项

- 所有密码都是学习用的弱密码，不要照搬到任何真实环境。
- `node-exporter` 在 macOS 上记的是 OrbStack Linux 虚拟机的指标，不是 macOS 本体。
- 端口如果冲突，改 `.env` 里的对应变量即可。
