#!/bin/sh
set -e

KOPIA_REPO_PATH="${KOPIA_REPO_PATH:-/app/repository}"
KOPIA_CACHE_DIRECTORY="${KOPIA_CACHE_DIRECTORY:-/app/cache}"
KOPIA_LOG_DIR="${KOPIA_LOG_DIR:-/app/logs}"

export KOPIA_PASSWORD
export KOPIA_CACHE_DIRECTORY
export KOPIA_LOG_DIR

if [ -z "$KOPIA_PASSWORD" ]; then
  echo "ERROR: KOPIA_PASSWORD is required to create or access the repository."
  exit 1
fi

mkdir -p "$KOPIA_REPO_PATH" "$KOPIA_CACHE_DIRECTORY" "$KOPIA_LOG_DIR"

# Create repository if it doesn't already exist (first deploy)
if [ ! -f "$KOPIA_REPO_PATH/kopia.repository.f" ]; then
  echo "Initializing Kopia repository at $KOPIA_REPO_PATH..."
  kopia repository create filesystem \
    --path "$KOPIA_REPO_PATH" \
    --override-username=server \
    --override-hostname=server
  echo "Repository created successfully."
else
  echo "Connecting to existing repository at $KOPIA_REPO_PATH..."
  kopia repository connect filesystem \
    --path "$KOPIA_REPO_PATH" \
    --override-username=server \
    --override-hostname=server
fi

SERVER_USER="${KOPIA_SERVER_USERNAME:-kopia}"

# Create an initial client user on first boot so users can connect immediately.
# KOPIA_CLIENT_USERNAME defaults to the same basic-auth user; its password is
# KOPIA_CLIENT_PASSWORD (falls back to the repository password if unset).
CLIENT_USER="${KOPIA_CLIENT_USERNAME:-$SERVER_USER@railway}"
CLIENT_PASS="${KOPIA_CLIENT_PASSWORD:-$KOPIA_PASSWORD}"

if ! kopia server user list 2>/dev/null | grep -q "^${CLIENT_USER}$"; then
  echo "Creating initial client user: $CLIENT_USER"
  kopia server user add "$CLIENT_USER" --user-password="$CLIENT_PASS" || \
    echo "WARN: could not add client user (may already exist)"
fi

echo "Starting Kopia server on port ${PORT:-51515}..."

# exec replaces the shell so kopia receives signals directly
# Railway terminates TLS at the edge, so we run with --insecure
# gRPC is enabled (no --no-grpc) to support kopia backup clients
exec kopia server start \
  --address=0.0.0.0:${PORT:-51515} \
  --insecure \
  --server-username="$SERVER_USER" \
  --server-password="${KOPIA_SERVER_PASSWORD:?KOPIA_SERVER_PASSWORD is required}" \
  --no-check-for-updates
