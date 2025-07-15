#!/usr/bin/env bash
# scripts/start_test_db.sh
# -------------------------------------------------------------
# Spin up (or re-attach to) a lightweight Postgres 15 container
# called "bee_test_pg" on a random free host port between
# 55433-55633.  Prints two export lines so callers can capture
# DB_HOST / DB_PORT environment variables.
# -------------------------------------------------------------

set -euo pipefail

NAME="bee_test_pg"
IMAGE="postgres:15"
DB_NAME="${DB_NAME:-test}"
DB_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
PORT_START=55433
PORT_END=55633

# If container already running, reuse it ----------------------
if docker ps -f "name=${NAME}" --format '{{.ID}}' | grep -q .; then
  cid=$(docker ps -f "name=${NAME}" --format '{{.ID}}')
  host_port=$(docker inspect --format '{{ (index (index .NetworkSettings.Ports "5432/tcp") 0).HostPort }}' "$cid")
  echo "export DB_HOST=localhost"
  echo "export DB_PORT=$host_port"
  exit 0
fi

# If container exists but stopped, remove it first ------------
if docker ps -a -f "name=${NAME}" --format '{{.ID}}' | grep -q .; then
  docker rm "$NAME" >/dev/null
fi

# Pick a free port in range -----------------------------------
FREE_PORT=""
for port in $(seq $PORT_START $PORT_END); do
  if ! lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    FREE_PORT="$port"
    break
  fi
done

if [[ -z "$FREE_PORT" ]]; then
  echo "❌  No free port in range ${PORT_START}-${PORT_END}" >&2
  exit 1
fi

# Run container ----------------------------------------------
docker run -d --name "$NAME" \
  -e POSTGRES_PASSWORD="$DB_PASSWORD" \
  -e POSTGRES_DB="$DB_NAME" \
  -p "${FREE_PORT}:5432" \
  "$IMAGE" >/dev/null

echo "🐘 Started Postgres container \"$NAME\" on host port $FREE_PORT"
# Wait for server readiness (max 10 seconds)
for i in {1..20}; do
  if PGPASSWORD=$DB_PASSWORD pg_isready -h localhost -p $FREE_PORT -d $DB_NAME -U postgres >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

if ! PGPASSWORD=$DB_PASSWORD pg_isready -h localhost -p $FREE_PORT -d $DB_NAME -U postgres >/dev/null 2>&1; then
  echo "⚠️  Postgres container not ready after 10s" >&2
fi

echo "export DB_HOST=localhost"
echo "export DB_PORT=$FREE_PORT" 