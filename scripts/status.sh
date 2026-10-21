#!/usr/bin/env bash
# 查看某个 profile 的运行状态。用法：./scripts/status.sh core
set -euo pipefail

PROFILES="${1:-core}"
COMPOSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../compose" && pwd)"

IFS=',' read -ra LIST <<< "$PROFILES"
args=()
for p in "${LIST[@]}"; do
  args+=(--profile "$p")
done

docker compose -f "$COMPOSE_DIR/docker-compose.yml" --env-file "$COMPOSE_DIR/../.env" "${args[@]}" ps
