# 中间件

## Redis

### 单机

```bash
make up PROFILE=redis
docker exec -it ops-lab-redis-1 redis-cli
```

练习清单：

1. 五大数据结构各试 10 个命令：`get/set`、`hget/hset`、`lpush/lrange`、`sadd/smembers`、`zadd/zrange`。
2. `type <key>`、`object encoding <key>`：看底层编码。
3. `slowlog get`：看慢查询日志。
4. `config get maxmemory`、`info memory`：看内存策略。
5. 设置 `maxmemory-policy allkeys-lru`，灌一堆 key，观察淘汰。

### 主从 + 哨兵

```bash
make up PROFILE=redis-ha
docker exec -it ops-lab-redis-master-1 redis-cli -p 6379 info replication
```

手动杀掉 master，观察哨兵 5 秒后判定客观下线，然后选举一个 replica 升主。

### Cluster

```bash
make up PROFILE=redis-cluster
docker exec -it ops-lab-rc-1-1 redis-cli -p 6379 cluster info
```

连接本机网关 `redis-cli -p 7000`，练习跨槽位操作时的 `MOVED` 重定向。

## MySQL

```bash
make up PROFILE=db
docker exec -it ops-lab-mysql-1 mysql -uroot -proot123
```

练习：`explain` 看执行计划、慢查询日志、主从复制。

## PostgreSQL

```bash
docker exec -it ops-lab-postgres-1 psql -U postgres -d labdb
```

库里已经建了 `orders` 表并插了 5 万行数据。练习 `EXPLAIN ANALYZE`。

## Kafka / RabbitMQ

```bash
make up PROFILE=mq
```

RabbitMQ 管理界面：<http://localhost:15672>（admin / admin123）
