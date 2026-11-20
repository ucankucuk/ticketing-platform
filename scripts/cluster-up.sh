#!/usr/bin/env bash
# Yerel kind cluster'ını oluşturur, Cilium'u kurar ve düğümlerin hazır olmasını bekler.
# Kullanım: ./scripts/cluster-up.sh [--with-argocd]
set -euo pipefail

CLUSTER_NAME="ticketing-local"
CILIUM_VERSION="1.20.2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
KIND_CONFIG="${ROOT_DIR}/platform/local/kind-cluster.yaml"
CILIUM_VALUES="${ROOT_DIR}/platform/cilium/values.yaml"

for tool in docker kind kubectl helm; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Gerekli araç bulunamadı: $tool" >&2; exit 1; }
done

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "Cluster zaten var: $CLUSTER_NAME"
else
  kind create cluster --config "$KIND_CONFIG"
fi

kubectl config use-context "kind-${CLUSTER_NAME}"

# CNI: Cilium (ADR-0012). Kurulana kadar düğümler NotReady kalır.
helm repo add cilium https://helm.cilium.io/ >/dev/null 2>&1 || true
helm repo update cilium >/dev/null
helm upgrade --install cilium cilium/cilium \
  --version "$CILIUM_VERSION" \
  --namespace kube-system \
  --values "$CILIUM_VALUES" \
  --wait --timeout 10m

kubectl -n kube-system rollout status daemonset/cilium --timeout=300s
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes -L topology.kubernetes.io/zone

if [[ "${1:-}" == "--with-argocd" ]]; then
  # Argo CD kurulumu (ADR-0007). Sürüm sabitlemesi Argo CD adımında yapılacak.
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -n argocd --server-side \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
  echo "Argo CD hazır. İlk admin parolası:"
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
fi
