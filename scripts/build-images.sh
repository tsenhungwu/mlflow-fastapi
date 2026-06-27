#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="${REGISTRY:-}"
VERSION="${1:-v1.0.0}"

IMAGE_PREFIX="mlflow-platform"

build_image() {
  local name="$1"
  local context="$2"
  local tag="${REGISTRY}${IMAGE_PREFIX}/${name}:${VERSION}"

  echo "Building ${tag}..."
  docker build -t "${tag}" "${context}"
}

build_image mlflow "${ROOT_DIR}/mlflow"
build_image train "${ROOT_DIR}/train"
build_image serving "${ROOT_DIR}/app"

if [[ -n "${REGISTRY}" ]]; then
  echo "Pushing images to ${REGISTRY}..."
  docker push "${REGISTRY}${IMAGE_PREFIX}/mlflow:${VERSION}"
  docker push "${REGISTRY}${IMAGE_PREFIX}/train:${VERSION}"
  docker push "${REGISTRY}${IMAGE_PREFIX}/serving:${VERSION}"
fi

echo "Done. Images:"
echo "  ${IMAGE_PREFIX}/mlflow:${VERSION}"
echo "  ${IMAGE_PREFIX}/train:${VERSION}"
echo "  ${IMAGE_PREFIX}/serving:${VERSION}"