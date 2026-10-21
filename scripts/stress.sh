#!/usr/bin/env bash
# 压测演示应用，练习容量与告警。用法：./scripts/stress.sh 60
set -euo pipefail

DURATION="${1:-60}"
URL="${2:-http://localhost:8081}"

echo "压测 $URL ${DURATION}s ..."
echo "可观察 Grafana：RPS、P95 延迟、CPU 使用率"
echo

if command -v hey >/dev/null; then
  exec hey -z "${DURATION}s" -c 20 "$URL/"
elif command -v ab >/dev/null; then
  exec ab -t "$DURATION" -c 20 "$URL/"
else
  echo "未找到压测工具，可安装：brew install hey"
  exit 1
fi
