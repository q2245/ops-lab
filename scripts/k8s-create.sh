#!/usr/bin/env bash
# 创建 kind 集群并部署示例。用法：./scripts/k8s-create.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "检查 kind ..."
command -v kind >/dev/null || { echo "请先安装：brew install kind"; exit 1; }

echo "创建集群（约 3-5 分钟）..."
kind create cluster --config "$ROOT/k8s/kind-config.yaml" --wait 300s

echo "设置 kubectl context ..."
kubectl config use-context kind-ops-lab

echo "部署示例 ..."
kubectl apply -f "$ROOT/k8s/manifests"

echo "等待 Pod 就绪 ..."
kubectl -n ops-lab rollout status deployment/demo-app --timeout=180s

echo
echo "集群已就绪。访问："
echo "  kubectl get pods -n ops-lab"
echo "  curl http://localhost:30080/"
echo
echo "删除集群：kind delete cluster --name ops-lab"
