#!/usr/bin/env bash
# Yerel kind cluster'ını oluşturur, Cilium'u ve Argo CD'yi kurar.
# Kullanım: ./scripts/cluster-up.sh [--no-argocd]
#   --no-argocd  Argo CD'yi kurmaz (CI smoke testi için)
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

if [[ "${1:-}" == "--no-argocd" ]]; then
  exit 0
fi

# GitOps: Argo CD (ADR-0019). İlk kurulum betikle yapılır; sonrasında Argo CD
# kendini ve platform bileşenlerini Git'teki deploy/argocd dizininden yönetir.
kubectl apply --server-side --force-conflicts -k "${ROOT_DIR}/deploy/argocd/bootstrap"
kubectl -n argocd wait --for=condition=Established crd/applications.argoproj.io --timeout=120s
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

kubectl apply -f "${ROOT_DIR}/deploy/argocd/root-app.yaml"

echo
echo "Argo CD hazır. Arayüz için: kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo "Kullanıcı adı: admin"
echo -n "İlk admin parolası: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
