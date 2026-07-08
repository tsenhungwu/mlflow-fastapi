#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY="${1:-base}"

NAMESPACE="mlflow-fastapi"
IMAGE_PREFIX="mlflow-platform"
VERSION=${IMAGE_VERSION:?IMAGE_VERSION is required}

IMAGES=(
  "mlflow"
  "train"
  "serving"
)

if [[ "${OVERLAY}" == "base" ]]; then
  KUSTOMIZE_PATH="${ROOT_DIR}/k8s/base"
elif [[ -d "${ROOT_DIR}/k8s/overlays/${OVERLAY}" ]]; then
  KUSTOMIZE_PATH="${ROOT_DIR}/k8s/overlays/${OVERLAY}"
else
  echo "Overlay not found: ${OVERLAY}" >&2
  echo "Use 'base' or one of:" >&2
  find "${ROOT_DIR}/k8s/overlays" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null || true
  exit 1
fi

echo "Building container images..."
IMAGE_VERSION="${VERSION}" \
"${ROOT_DIR}/scripts/build-images.sh"

if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
  echo "Loading images into Minikube..."

  for image in "${IMAGES[@]}"; do
    minikube image load "${IMAGE_PREFIX}/${image}:${VERSION}"
  done
fi

echo "Creating namespace..."
kubectl apply -f "${ROOT_DIR}/k8s/base/namespace.yaml"

echo "Removing previous train job (if any)..."
kubectl delete job train -n "${NAMESPACE}" --ignore-not-found

echo "Updating image versions..."
pushd "${KUSTOMIZE_PATH}" >/dev/null
for image in "${IMAGES[@]}"; do
  kustomize edit set image \
    "${IMAGE_PREFIX}/${image}=${IMAGE_PREFIX}/${image}:${VERSION}"
done
popd >/dev/null

echo "Applying Kubernetes manifests (overlay: ${OVERLAY})..."
kubectl apply -k "${KUSTOMIZE_PATH}"

echo ""
echo "Waiting for workloads..."
kubectl -n "${NAMESPACE}" rollout status deployment/mlflow --timeout=120s
kubectl -n "${NAMESPACE}" wait --for=condition=complete job/train --timeout=300s
kubectl -n "${NAMESPACE}" rollout status deployment/serving --timeout=300s

echo ""
echo "Deployment complete."
echo ""
kubectl -n "${NAMESPACE}" get pods,svc
