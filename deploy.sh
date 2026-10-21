#!/usr/bin/env bash
# Usage: ./deploy.sh <eks|oci|local>
set -euo pipefail
cd "$(dirname "$0")"

TARGET="${1:-}"
if [[ "$TARGET" != "eks" && "$TARGET" != "oci" && "$TARGET" != "local" ]]; then
  echo "Usage: $0 <eks|oci|local>" >&2
  exit 1
fi
NS="${NAMESPACE:-gitlab-ivs}"
RELEASE="${RELEASE:-gitlab}"

GITLAB_VALUES=(-f values.yaml)
DEPS_VALUES=(-f gitlab-deps/values.yaml)
# Layer the cloud-specific overlay on top of the shared values.
GITLAB_VALUES+=(-f "values-$TARGET.yaml")
[[ -f "gitlab-deps/values-$TARGET.yaml" ]] && DEPS_VALUES+=(-f "gitlab-deps/values-$TARGET.yaml")

# Helm 4's default kstatus hook watcher can hang on GitLab's hook Jobs; use the legacy waiter.
WAIT=(--wait)
[[ "$(helm version --short)" == v4* ]] && WAIT=(--wait=legacy)

# Cluster-level prerequisites for the target (e.g. a StorageClass on OCI).
if [[ -d "$TARGET" && "$TARGET" != "local" ]]; then
  find "$TARGET" -maxdepth 1 -name '*.yaml' -exec kubectl apply -f {} \;
fi

# External object storage keys (objectStore: external) come from the environment, never a values file.
if [[ -n "${S3_ACCESS_KEY:-}" && -n "${S3_SECRET_KEY:-}" ]]; then
  DEPS_VALUES+=(--set-string "external.accessKey=$S3_ACCESS_KEY" --set-string "external.secretKey=$S3_SECRET_KEY")
fi

echo ">> Installing PostgreSQL / Valkey / MinIO into $NS"
helm upgrade --install gitlab-deps ./gitlab-deps -n "$NS" --create-namespace "${DEPS_VALUES[@]}" "${WAIT[@]}" --timeout 10m

echo ">> Installing GitLab ($TARGET)"
helm upgrade --install "$RELEASE" ./gitlab -n "$NS" "${GITLAB_VALUES[@]}" "${WAIT[@]}" --timeout 30m

if [[ "$TARGET" == "local" ]]; then
  kubectl apply -f local/istio-routing.yaml
fi

# Target-specific resources that need GitLab (or its cert-manager CRDs) installed first.
if [[ -d "$TARGET/post" ]]; then
  kubectl apply -f "$TARGET/post/"
fi

echo ">> Root password:"
echo "   kubectl get secret $RELEASE-gitlab-initial-root-password -n $NS -o jsonpath='{.data.password}' | base64 -d; echo"
