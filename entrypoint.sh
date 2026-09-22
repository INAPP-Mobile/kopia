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

# Ensure directories exist (volume may be root-owned)
mkdir -p "$KOPIA_REPO_PATH" "$KOPIA_CACHE_DIRECTORY" "$KOPIA_LOG_DIR"

# Create repository if it doesn't already exist (first deploy)
if [ ! -f "$KOPIA_REPO_PATH/kopia.repository.f" ]; then
  echo "Initializing Kopia repository at $KOPIA_REPO_PATH..."
  kopia repository create filesystem \
    --path "$KOPIA_REPO_PATH"
  echo "Repository created successfully."
else
  echo "Connecting to existing repository at $KOPIA_REPO_PATH..."
  kopia repository connect filesystem \
    --path "$KOPIA_REPO_PATH"
fi

SERVER_USER="${KOPIA_SERVER_USERNAME:-kopia}"

echo "Starting Kopia server on port ${PORT:-51515}..."

# exec replaces the shell so kopia receives signals directly
exec kopia server start \
  --address=0.0.0.0:${PORT:-51515} \
  --server-username="$SERVER_USER" \
  --server-password="${KOPIA_SERVER_PASSWORD:-$KOPIA_PASSWORD}"
