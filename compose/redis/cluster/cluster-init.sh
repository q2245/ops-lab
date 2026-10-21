#!/bin/sh
# Redis Cluster 初始化：三主三从，练习 16384 槽位、MOVED 重定向、reshard
set -e

echo "等待各节点就绪..."
for node in rc-1 rc-2 rc-3 rc-4 rc-5 rc-6; do
  until redis-cli -h "$node" -p 6379 ping >/dev/null 2>&1; do
    echo "  等待 $node ..."
    sleep 2
  done
  echo "  $node 已就绪"
done

echo "检查集群是否已初始化..."
if redis-cli -h rc-1 -p 6379 cluster info 2>/dev/null | grep -q "cluster_state:ok"; then
  echo "集群已经是 ok 状态，跳过初始化。"
  exit 0
fi

echo "创建集群（3 主 3 从）..."
# yes 表示接受默认的槽位分配方案
redis-cli --cluster create \
  rc-1:6379 rc-2:6379 rc-3:6379 \
  rc-4:6379 rc-5:6379 rc-6:6379 \
  --cluster-replicas 1 --cluster-yes

echo "集群状态："
redis-cli -h rc-1 -p 6379 cluster info
echo
echo "节点分布："
redis-cli -h rc-1 -p 6379 cluster nodes
