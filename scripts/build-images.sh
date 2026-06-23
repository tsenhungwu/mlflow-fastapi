#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="${REGISTRY:-}"

build_image() {
  local name="$1"
  local context="$2"
  local tag="${REGISTRY}${name}:latest"

  echo "Building ${tag}..."
  docker build -t "${tag}" "${context}"
}

build_image mlflow-fastapi-mlflow "${ROOT_DIR}/mlflow"
build_image mlflow-fastapi-train "${ROOT_DIR}/train"
build_image mlflow-fastapi-serving "${ROOT_DIR}/app"

if [[ -n "${REGISTRY}" ]]; then
  echo "Pushing images to ${REGISTRY}..."
  docker push "${REGISTRY}mlflow-fastapi-mlflow:latest"
  docker push "${REGISTRY}mlflow-fastapi-train:latest"
  docker push "${REGISTRY}mlflow-fastapi-serving:latest"
fi

echo "Done. Images:"
echo "  mlflow-fastapi-mlflow:latest"
echo "  mlflow-fastapi-train:latest"
echo "  mlflow-fastapi-serving:latest"
