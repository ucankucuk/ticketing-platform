#!/usr/bin/env bash
# Yerel kind cluster'ını oluşturur ve düğümlerin hazır olmasını bekler.
# Kullanım: ./scripts/cluster-up.sh [--with-argocd]
set -euo pipefail

CLUSTER_NAME="ticketing-local"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/../platform/local/kind-cluster.yaml"

for tool in docker kind kubectl; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Gerekli araç bulunamadı: $tool" >&2; exit 1; }
done

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "Cluster zaten var: $CLUSTER_NAME"
else
  kind create cluster --config "$CONFIG"
fi

kubectl config use-context "kind-${CLUSTER_NAME}"
kubectl wait --for=condition=Ready nodes --all --timeout=180s
kubectl get nodes -L topology.kubernetes.io/zone

if [[ "${1:-}" == "--with-argocd" ]]; then
  # Argo CD kurulumu (ADR-0007). Sürüm sabitlemesi platform fazında yapılacak.
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -n argocd --server-side \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
  echo "Argo CD hazır. İlk admin parolası:"
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
fi
