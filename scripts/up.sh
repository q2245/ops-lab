#!/usr/bin/env bash
# 启动一组 profile 的服务。用法：./scripts/up.sh core
set -euo pipefail

PROFILES="${1:-core}"
COMPOSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../compose" && pwd)"

IFS=',' read -ra LIST <<< "$PROFILES"
args=()
for p in "${LIST[@]}"; do
  args+=(--profile "$p")
done

echo "启动 profiles: ${PROFILES}"
docker compose --project-directory "$COMPOSE_DIR/.." -f "$COMPOSE_DIR/docker-compose.yml" --env-file "$COMPOSE_DIR/../.env" "${args[@]}" up -d
echo "完成。查看状态：docker compose -f $COMPOSE_DIR/docker-compose.yml ${args[*]} ps"
