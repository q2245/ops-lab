# Ops Lab 运维学习实验室

这是一套可以直接跑在本地 macOS 上的运维练习环境。它不是把一堆软件随便起起来，而是围绕一条完整的学习链路组织：

**Linux / 网络 -> 可观测性 -> 中间件 -> 负载均衡 -> Kubernetes -> CI/CD**

环境使用 Docker Compose 分组启动，K8s 部分使用 kind。你可以在里面制造慢请求、错误、后端宕机、Redis 主从切换等故障，再用 Prometheus、Grafana、Loki、Jaeger 去观察和定位。

## 环境要求

| 工具 | 是否必须 | 说明 |
|------|---------|------|
| Docker Desktop / OrbStack | 必须 | 提供 Docker 引擎 |
| Docker Compose v2 | 必须 | 命令格式是 `docker compose`，不是旧的 `docker-compose` |
| kind | K8s 部分需要 | 安装：`brew install kind` |
| kubectl | K8s 部分需要 | `brew install kubectl` |
| hey / ab | 可选 | 压测演示应用：`brew install hey` |

## 快速开始

```bash
git clone git@github.com:q2245/ops-lab.git
cd ops-lab

docker compose version
make up PROFILE=core
```

启动完成后访问：

| 入口 | 地址 | 账号 |
|------|------|------|
| Ops Lab 控制台 | <http://localhost:8081> | 无 |
| Prometheus 观测台 | <http://localhost:8081/prometheus> | 无 |
| Grafana | <http://localhost:3000> | admin / admin |
| Prometheus | <http://localhost:9090> | 无 |
| Alertmanager | <http://localhost:9093> | 无 |
| Loki API | <http://localhost:3100/ready> | 无 |

`core` 是这套实验的主入口。它会启动：

- Prometheus：抓取和保存指标
- Grafana：查看预置的 Lab Overview Dashboard
- Alertmanager：接收告警
- Loki + Alloy：收集容器日志
- Node Exporter / cAdvisor / Blackbox Exporter：主机、容器、网络探测指标
- demo-app：演示应用和 Ops Lab 控制台

第一次启动会下载镜像，可能需要几分钟。

## Profile 总览

不要一次性启动所有服务，按学习阶段启动即可。

| Profile | 用途 | 主要组件 | 启动命令 |
|---------|------|----------|----------|
| `core` | 指标、日志、告警、控制台 | Prometheus, Grafana, Loki, Alloy, Alertmanager, exporters, demo-app | `make up PROFILE=core` |
| `tracing` | 链路追踪 | Jaeger, OpenTelemetry Collector, demo-app | `make up PROFILE=tracing` |
| `lb` | Nginx / HAProxy 负载均衡 | Nginx, HAProxy, backend-a, backend-b | `make up PROFILE=lb` |
| `redis` | Redis 单机 | Redis 8 | `make up PROFILE=redis` |
| `redis-ha` | 主从 + 哨兵 | 1 主、2 从、3 Sentinel | `make up PROFILE=redis-ha` |
| `redis-cluster` | 集群分片 | 三主三从 | `make up PROFILE=redis-cluster` |
| `db` | 数据库 | MySQL 8.4, PostgreSQL 17 | `make up PROFILE=db` |
| `mq` | 消息队列 | Kafka 4, RabbitMQ 4 | `make up PROFILE=mq` |
| `cicd` | Git / CI | Gitea, Gitea Actions Runner | `make up PROFILE=cicd` |
| `linux` | Linux / 网络排障 | netshoot, Ubuntu, stress target | `make up PROFILE=linux` |

停止对应组：

```bash
make down PROFILE=core
```

查看状态和日志：

```bash
make ps PROFILE=core
make logs PROFILE=core
```

## Demo App 控制台

访问 <http://localhost:8081>。页面里有四张实时指标卡：

| 指标 | PromQL |
|------|--------|
| 请求总数 | `sum(demo_http_requests_total)` |
| 5 分钟 QPS | `sum(rate(demo_http_requests_total[5m]))` |
| 错误率 | `100 * sum(rate(demo_http_requests_total{status=~"5.."}[5m])) / sum(rate(demo_http_requests_total[5m]))` |
| P95 延迟 | `histogram_quantile(0.95, sum by (le) (rate(demo_http_request_duration_seconds_bucket[5m])))` |

可用按钮：

| 按钮 | 行为 |
|------|------|
| 正常请求 | 访问 `/`，产生成功请求 |
| 慢请求 | 访问 `/slow`，延迟约 1.5 到 2.5 秒 |
| 错误请求 | 访问 `/error`，返回 500 |
| 10 次混合 | 并发发送正常、慢请求和错误请求 |

直接调用接口也可以：

```bash
curl http://localhost:8081/
curl http://localhost:8081/slow
curl http://localhost:8081/error
curl http://localhost:8081/healthz
curl http://localhost:8081/readyz
curl http://localhost:8081/metrics
```

## 练习一：可观测性闭环

### 1. 造流量

在控制台点几次「10 次混合」，或者执行：

```bash
make stress
```

### 2. 看 Grafana

访问 <http://localhost:3000>，打开 `Lab Overview`。

重点看：

- QPS 是否上升
- P95 是否被 `/slow` 抬高
- 5xx 数量是否增加
- 容器 CPU / 内存变化
- 日志里是否出现 `trace_id`

### 3. 用 Prometheus 观测台

访问 <http://localhost:8081/prometheus>。这个页面把 Prometheus 原生 API 做成一屏可操作的观测台：

| 区域 | 用途 |
|------|------|
| 指标卡 | 查看 UP 目标、QPS、错误率、P95、firing 告警和规则组数量 |
| PromQL 查询 | 输入任意即时查询，或点 QPS、错误率、P95、CPU、容器内存等快捷按钮 |
| 采集目标 | 确认每个 scrape job 是 UP 还是 DOWN |
| 告警 | 查看 pending / firing 状态 |
| 规则组 | 确认告警规则和 recording rules 已加载 |

推荐练习：先在「采集目标」确认服务都为 UP；回到 Ops Lab 控制台点几次「10 次混合」；再回到观测台执行 QPS、错误率和 P95 查询。`rate(...[5m])` 需要样本积累，刚启动时等 15 到 30 秒；如果结果为 `NaN`，页面会显示 `--`。

### 4. 看日志

Grafana 里进入 Explore，选择 Loki：

```logql
{container="demo-app"}
```

查错误：

```logql
{container="demo-app"} |= "simulated server error"
```

### 5. 看告警

访问 <http://localhost:9090/alerts> 和 <http://localhost:9093>。

持续触发错误后，观察 `DemoAppHighErrorRate` 是否进入 Alertmanager。 Prometheus 规则在：

```text
compose/prometheus/rules/lab-alerts.yml
```

### 6. 看链路

启动 tracing：

```bash
make up PROFILE=tracing
```

访问 <http://localhost:16686>，选择 `demo-app`，点 Find Traces。日志里的 `trace_id` 可以在 Grafana 里跳转到 Jaeger。

## 练习二：Nginx 负载均衡

启动：

```bash
make up PROFILE=lb
open http://localhost:18080
```

Nginx 实验台会显示请求落在哪个后端。`/api/backend` 会返回：

```http
X-Upstream: <backend-ip>:80
```

连发 10 次：

```bash
for i in $(seq 1 10); do
  curl -sS -o /dev/null -D - http://localhost:18080/api/backend |
    awk -F': ' 'tolower($1)=="x-upstream" {print $2}' | tr -d '\r'
done
```

演练后端故障：

```bash
docker stop ops-lab-backend-a-1
curl -i http://localhost:18080/api/backend

docker start ops-lab-backend-a-1
```

观察 Nginx 如何处理失败后端，以及后端恢复后流量是否回来。

HAProxy 状态页：

<http://localhost:8404/stats>

注意：HAProxy 本机端口是 `80`，Nginx 端口是 `18080`，避免和 macOS 上已有服务冲突。

## 练习三：Redis 运维

### 单机

```bash
make up PROFILE=redis
docker exec -it ops-lab-redis-1 redis-cli
```

练习：

```redis
INFO memory
INFO stats
CONFIG GET maxmemory
CONFIG SET maxmemory-policy allkeys-lru
SLOWLOG GET
```

### 主从 + 哨兵

```bash
make up PROFILE=redis-ha
```

查看复制关系：

```bash
docker exec -it ops-lab-redis-master-1 redis-cli info replication
```

手动触发主从切换：

```bash
docker stop ops-lab-redis-master-1
```

观察 Sentinel 日志：

```bash
docker logs -f ops-lab-sentinel-1
```

本机 Sentinel 端口：

```bash
redis-cli -h 127.0.0.1 -p 26379 sentinel get-master-addr-by-name mymaster
```

### Cluster

```bash
make up PROFILE=redis-cluster
redis-cli -p 7000 cluster info
```

练习 `MOVED` 重定向和不同 slot 的 key 分布。

## 练习四：数据库

```bash
make up PROFILE=db
```

MySQL：

```bash
docker exec -it ops-lab-mysql-1 mysql -uroot -proot123
```

```sql
SHOW DATABASES;
SHOW VARIABLES LIKE 'slow_query_log%';
SHOW PROCESSLIST;
```

PostgreSQL：

```bash
docker exec -it ops-lab-postgres-1 psql -U postgres -d labdb
```

PostgreSQL 启动时会初始化 `orders` 表并写入 5 万行数据，适合练习：

```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 42;
EXPLAIN ANALYZE SELECT status, count(*) FROM orders GROUP BY status;
```

## 练习五：Kubernetes

kind 集群结构：

```text
ops-lab
├── control-plane
├── worker-1   zone: lab-a
└── worker-2   zone: lab-b
```

创建集群：

```bash
make k8s
```

脚本会自动完成：

1. 创建 1 个 control-plane 和 2 个 worker。
2. 把本机 `30080` 映射到 kind 的 NodePort。
3. 部署 `ops-lab` namespace。
4. 部署三副本 `demo-app`。
5. 配置 Service、NodePort、PodDisruptionBudget、NetworkPolicy、HPA。
6. 等待 Deployment 就绪。

访问：

```bash
curl http://localhost:30080/
```

查看状态：

```bash
kubectl -n ops-lab get all
kubectl -n ops-lab get pods -o wide
kubectl -n ops-lab describe hpa demo-app
kubectl -n ops-lab get networkpolicy
```

因为 demo-app 使用 Pod 反亲和，三个副本会尽量分散到不同节点。可以用下面的命令观察调度结果：

```bash
kubectl -n ops-lab get pods -o wide
kubectl get nodes --show-labels
```

删除 K8s 环境：

```bash
make k8s-delete
```

## CI/CD

```bash
make up PROFILE=cicd
open http://localhost:3200
```

Gitea 用来练习仓库、Webhook、Actions 和 Runner 的基础流程。学习重点不是记住界面，而是理解：

- 每次 commit 自动 lint / test / build
- 镜像 tag 使用 commit hash，而不是 `latest`
- 发布要可重复、可回滚
- 配置和代码分离

> 当前 Compose 里的 `GITEA_RUNNER_REGISTRATION_TOKEN=CHANGE_ME`。练习 Actions 前，需要按 Gitea 文档重新注册 Runner。

## Linux / 网络

```bash
make up PROFILE=linux
docker exec -it ops-lab-toolbox-1 bash
```

常用命令：

```bash
ip addr
ip route
ss -tunlp
dig +trace example.com
traceroute example.com
tcpdump -i any port 80
curl -v http://localhost:18080/
```

如果 `lb` 和 `linux` 一起开着，可以在 toolbox 里抓包，同时在宿主机访问 Nginx 实验台。

## 常见排查

### 端口冲突

先看谁占了端口：

```bash
docker ps
lsof -nP -iTCP -sTCP:LISTEN
```

然后修改 `.env`，例如：

```dotenv
NGINX_PORT=18080
GRAFANA_PORT=3000
PROMETHEUS_PORT=9090
```

### 服务一直重启

```bash
make ps PROFILE=core
docker logs --tail 100 ops-lab-nginx-1
docker inspect ops-lab-nginx-1 | less
```

### Prometheus 没有数据

1. 打开 <http://localhost:9090/targets>。
2. 确认 target 是 `UP`。
3. 在控制台点几个请求，等 10 到 15 秒。
4. 到 Prometheus 执行 `demo_http_requests_total`。

### Grafana 登录失败

默认账号在 `.env`：

```dotenv
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin
```

### K8s Pod 一直是 Pending

```bash
kubectl -n ops-lab describe pod <pod-name>
kubectl get events -A --sort-by='.lastTimestamp'
```

常见原因是镜像拉取慢、资源不足或 kind 集群没起来。

## 清理

只停当前组：

```bash
make down PROFILE=core
```

删除所有 Compose 服务和数据卷：

```bash
make clean
```

删除 kind 集群：

```bash
make k8s-delete
```

## 目录结构

```text
ops-lab/
├── compose/
│   ├── docker-compose.yml       # 所有 Compose 服务和 profile
│   ├── prometheus/              # Prometheus 配置、规则、targets
│   ├── grafana/                 # 数据源和 Dashboard 预配置
│   ├── alertmanager/            # 告警路由
│   ├── loki/                    # 日志存储
│   ├── alloy/                   # 日志采集
│   ├── nginx/                   # 反代、实验台、后端页面
│   ├── redis/                   # 单机、哨兵、Cluster 配置
│   ├── mysql/                   # MySQL 配置
│   ├── postgres/                # PostgreSQL 初始化 SQL
│   └── otel/                    # OpenTelemetry Collector 配置
├── demos/demo-app/
│   ├── app.go                   # 指标、健康检查、慢请求、错误接口
│   └── static/index.html        # Ops Lab 控制台
├── k8s/
│   ├── kind-config.yaml         # 多节点 kind 集群
│   └── manifests/               # Deployment, Service, NetworkPolicy, HPA
├── docs/
│   ├── 01-linux-network.md
│   ├── 02-observability.md
│   ├── 03-middleware.md
│   ├── 04-k8s.md
│   ├── 05-cicd.md
│   └── roadmap.md
└── Makefile
```

## 安全说明

- 这里所有账号密码只用于本地学习，不能复制到生产。
- Grafana、MySQL、PostgreSQL、RabbitMQ 的默认密码都在 `.env`。
- `gitea-runner` 默认挂载了 Docker socket，只建议在隔离的本地环境使用。
- 不要把这套环境直接暴露到公网。
