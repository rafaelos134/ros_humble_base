#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./run_container.sh linux
  ./run_container.sh nvidia
  ./run_container.sh rasp
  ./run_container.sh rootless

Description:
  Exports LOCAL_UID and LOCAL_GID from the current host user,
  then runs the matching Docker Compose file.
EOF
}

if [ $# -ne 1 ]; then
  usage
  exit 1
fi

case "$1" in
  linux)
    COMPOSE_FILE="compose_linux.yaml"
    ;;
  nvidia)
    COMPOSE_FILE="compose_linux_nvidia.yaml"
    ;;
  rasp)
    COMPOSE_FILE="compose_raspberrypi5.yaml"
    ;;
  rootless)
    COMPOSE_FILE="compose_linux_rootless.yaml"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    echo "Invalid target: $1"
    echo
    usage
    exit 1
    ;;
esac

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Compose file not found: $COMPOSE_FILE"
  exit 1
fi

export LOCAL_UID
LOCAL_UID="$(id -u)"

export LOCAL_GID
LOCAL_GID="$(id -g)"

echo "Using compose file: $COMPOSE_FILE"
echo "LOCAL_UID=$LOCAL_UID"
echo "LOCAL_GID=$LOCAL_GID"


# docker compose -f "$COMPOSE_FILE" up
docker compose -f "$COMPOSE_FILE" up --build