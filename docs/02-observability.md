# 可观测性：指标、日志、链路

可观测性三大支柱：**Metrics**（数字，便宜，适合聚合）、**Logs**（文本，贵，适合细节）、**Tracing**（请求视角，串联一次调用的全部环节）。

## 指标

### 启动

```bash
make up PROFILE=core
```

### 四种指标类型

| 类型 | 例子 | 什么时候用 |
|------|------|-----------|
| Counter | `demo_http_requests_total` | 只增不减：请求数、错误数 |
| Gauge | `node_memory_MemAvailable_bytes` | 可增可减：内存、队列长度 |
| Histogram | `demo_http_request_duration_seconds` | 延迟分布、算分位数 |
| Summary | - | 客户端算分位数，一般用 Histogram 代替 |

### 必会的 PromQL

```promql
up == 0

sum(rate(demo_http_requests_total[5m]))

sum(rate(demo_http_requests_total{status=~"5.."}[5m]))
  /
sum(rate(demo_http_requests_total[5m]))

histogram_quantile(0.95, sum by (le) (rate(demo_http_request_duration_seconds_bucket[5m])))

100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

sum by (name) (container_memory_working_set_bytes{name!=""})
```

核心理解：`rate()` 是「增长速度」，`[5m]` 是「时间窗口」，`by (...)` 是「分组维度」。这三件事组合起来就是 Prometheus 的全部。

## 告警

规则在 `compose/prometheus/rules/lab-alerts.yml`。一条告警的结构：

```yaml
- alert: TargetDown
  expr: up == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "..."
```

Alertmanager 负责去重、分组、静默、路由。配置在 `compose/alertmanager/alertmanager.yml`。

练习：访问 `curl http://localhost:8081/error` 十几次，等 5 分钟，看 Alertmanager 是否收到 DemoAppHighErrorRate 告警。

## 日志

Alloy 会自动把所有容器的 stdout/stderr 收进 Loki。在 Grafana 里用 LogQL 查：

```logql
{container="demo-app"}

{container="demo-app"} |= "trace_id"
```

Loki 的设计哲学是「不索引日志内容，只索引标签」。所以标签必须少而精，查询要靠 `|= "keyword"` 而不是靠标签过滤所有内容。

## 链路

```bash
make up PROFILE=tracing
```

访问 <http://localhost:16686>，选 `demo-app`，Find Traces。你能看到每次请求从进入到现在经过的每个 span，以及耗时分布。

关键概念：一个 trace 是一次请求的全链路，由多个 span 组成，span 之间有父子关系。Grafana 的 Loki 数据源配了 `derivedFields`，日志里的 `trace_id=xxx` 会变成可点击的链接，直接跳到 Jaeger 的对应 trace，这就是三大支柱联动的核心。
