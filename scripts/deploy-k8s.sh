#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY="${1:-base}"

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
"${ROOT_DIR}/scripts/build-images.sh"

if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
  echo "Loading images into minikube..."
  minikube image load mlflow-fastapi-mlflow:latest
  minikube image load mlflow-fastapi-train:latest
  minikube image load mlflow-fastapi-serving:latest
fi

echo "Creating namespace..."
kubectl apply -f "${ROOT_DIR}/k8s/base/namespace.yaml"

echo "Removing previous train job (if any)..."
kubectl delete job train -n mlflow-fastapi --ignore-not-found

echo "Applying Kubernetes manifests (overlay: ${OVERLAY})..."
kubectl apply -k "${KUSTOMIZE_PATH}"

echo ""
echo "Waiting for workloads..."
kubectl -n mlflow-fastapi rollout status deployment/mlflow --timeout=120s
kubectl -n mlflow-fastapi wait --for=condition=complete job/train --timeout=300s
kubectl -n mlflow-fastapi rollout status deployment/serving --timeout=300s

echo ""
echo "Deployment complete."
echo ""
kubectl -n mlflow-fastapi get pods,svc
