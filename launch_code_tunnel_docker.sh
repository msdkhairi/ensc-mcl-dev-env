#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-mcl-dev-env}"
CONTAINER_USERNAME="${CONTAINER_USERNAME:-dev}"
CONTAINER_NAME="${CONTAINER_NAME:-${CONTAINER_USERNAME}-remote}"
CONTAINER_HOME="${CONTAINER_HOME:-/home/$CONTAINER_USERNAME}"
HOST_WORKSPACE_DIR="${HOST_WORKSPACE_DIR:-${WORKSPACE_DIR:-/localhome/mka267/workspace}}"
CONTAINER_WORKSPACE_DIR="${CONTAINER_WORKSPACE_DIR:-$CONTAINER_HOME/workspace}"
HOST_CONDA_DIR="${HOST_CONDA_DIR:-/localhome/mka267/conda}"
DATASETS_DIR="${DATASETS_DIR:-/data/datasets}"
CONTAINER_CONDA_DIR="${CONTAINER_CONDA_DIR:-$CONTAINER_HOME/conda}"
CONTAINER_DATASETS_DIR="${CONTAINER_DATASETS_DIR:-$CONTAINER_HOME/project/data}"
DATA_ROOT="${DATA_ROOT:-/local-scratch/localhome/mka267/docker_root}"
EXEC_ROOT="${EXEC_ROOT:-/tmp/mka-docker-exec}"
SOCK_PATH="${SOCK_PATH:-/tmp/mka-docker-temp.sock}"
PID_FILE="${PID_FILE:-/tmp/dockerd-temp.pid}"
LOG_FILE="${LOG_FILE:-/tmp/dockerd-temp.log}"
AUTO_BUILD="${AUTO_BUILD:-1}"
REBUILD_IMAGE="${REBUILD_IMAGE:-0}"
RECREATE_CONTAINER="${RECREATE_CONTAINER:-0}"

cleanup() {
  if [[ -f "$PID_FILE" ]]; then
    echo "[INFO] Stopping temporary Docker daemon..."
    sudo kill "$(cat "$PID_FILE")" >/dev/null 2>&1 || true
    sudo rm -f "$PID_FILE" "$SOCK_PATH"
  fi
}
trap cleanup EXIT

mkdir -p "$DATA_ROOT" "$HOST_WORKSPACE_DIR" "$HOST_CONDA_DIR"
sudo -v
if [[ -f "$PID_FILE" ]] && sudo kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
  echo "[INFO] Stopping existing temporary Docker daemon..."
  sudo kill "$(cat "$PID_FILE")" >/dev/null 2>&1 || true
fi
sudo rm -f "$SOCK_PATH" "$PID_FILE"

echo "[INFO] Starting temporary Docker daemon with data-root: $DATA_ROOT"
sudo dockerd \
  --data-root "$DATA_ROOT" \
  --exec-root "$EXEC_ROOT" \
  --host "unix://$SOCK_PATH" \
  --pidfile "$PID_FILE" \
  > "$LOG_FILE" 2>&1 &

echo -n "[INFO] Waiting for temporary Docker daemon to be ready"
until DOCKER_HOST="unix://$SOCK_PATH" docker info >/dev/null 2>&1; do
  echo -n "."
  if [[ -f "$PID_FILE" ]] && ! sudo kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo
    echo "[ERROR] Temporary Docker daemon exited. Last log lines:"
    tail -n 80 "$LOG_FILE" || true
    exit 1
  fi
  sleep 1
done
echo " ready."

if [[ "$REBUILD_IMAGE" == "1" ]] || ! DOCKER_HOST="unix://$SOCK_PATH" docker image inspect "$IMAGE" >/dev/null 2>&1; then
  if [[ "$AUTO_BUILD" != "1" ]]; then
    echo "[ERROR] Docker image '$IMAGE' was not found in the custom Docker root."
    echo "[ERROR] Build it with:"
    echo "        DOCKER_HOST=unix://$SOCK_PATH docker build --build-arg USERNAME=$CONTAINER_USERNAME --build-arg UID=\$(id -u) --build-arg GID=\$(id -g) -t $IMAGE ."
    exit 1
  fi

  echo "[INFO] Building Docker image '$IMAGE' in the custom Docker root."
  DOCKER_HOST="unix://$SOCK_PATH" docker build \
    --build-arg USERNAME="$CONTAINER_USERNAME" \
    --build-arg UID="$(id -u)" \
    --build-arg GID="$(id -g)" \
    -t "$IMAGE" .
fi

if DOCKER_HOST="unix://$SOCK_PATH" docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  if [[ "$RECREATE_CONTAINER" == "1" ]]; then
    echo "[INFO] Removing existing container '$CONTAINER_NAME' so updated image/mounts/workdir can take effect."
    DOCKER_HOST="unix://$SOCK_PATH" docker rm -f "$CONTAINER_NAME"
  else
    echo "[INFO] Starting existing container '$CONTAINER_NAME'."
    echo "[INFO] Set RECREATE_CONTAINER=1 to replace it with the latest image/mounts/workdir."
    DOCKER_HOST="unix://$SOCK_PATH" docker start -ai "$CONTAINER_NAME"
    exit 0
  fi
fi

DOCKER_HOST="unix://$SOCK_PATH" docker run -it \
  --cpus=60 \
  --memory=240g \
  --memory-swap=240g \
  --shm-size=64g \
  --gpus=all \
  --volume "$HOST_WORKSPACE_DIR:$CONTAINER_WORKSPACE_DIR" \
  --volume "$HOST_CONDA_DIR:$CONTAINER_CONDA_DIR" \
  --volume "$DATASETS_DIR:$CONTAINER_DATASETS_DIR" \
  --workdir "$CONTAINER_WORKSPACE_DIR" \
  --name "$CONTAINER_NAME" \
  "$IMAGE" \
  bash
