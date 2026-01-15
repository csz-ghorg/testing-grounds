#!/bin/bash
# Diagnose why health checks aren't working

set -e

NAMESPACE="check-testing"
ARGOCD_NS="argocd"

echo "=== Diagnosing ArgoCD Health Check Issues ==="
echo ""

echo "1. Checking ConfigMap for health check customizations..."
echo ""

# Check KEDA health check
KEDA_HEALTH=$(kubectl get configmap argocd-cm -n "$ARGOCD_NS" -o jsonpath='{.data.resource\.customizations\.health\.Keda\.sh_ScaledObject}' 2>/dev/null || echo "")
if [ -z "$KEDA_HEALTH" ]; then
  echo "   ❌ KEDA health check NOT found in ConfigMap"
else
  echo "   ✓ KEDA health check found"
  # Check if it has escaped newlines
  if echo "$KEDA_HEALTH" | head -1 | grep -q '^local hs'; then
    echo "   ✓ Format looks correct (starts with 'local hs')"
  else
    echo "   ⚠️  Format issue: First line is: $(echo "$KEDA_HEALTH" | head -1)"
  fi
fi

# Check ExternalSecret health check
ES_HEALTH=$(kubectl get configmap argocd-cm -n "$ARGOCD_NS" -o jsonpath='{.data.resource\.customizations\.health\.external-secrets\.io_ExternalSecret}' 2>/dev/null || echo "")
if [ -z "$ES_HEALTH" ]; then
  echo "   ❌ ExternalSecret health check NOT found in ConfigMap"
else
  echo "   ✓ ExternalSecret health check found"
  if echo "$ES_HEALTH" | head -1 | grep -q '^local hs'; then
    echo "   ✓ Format looks correct"
  else
    echo "   ⚠️  Format issue: First line is: $(echo "$ES_HEALTH" | head -1)"
  fi
fi

echo ""
echo "2. Checking actual resource status in cluster..."
echo ""

# Check ExternalSecret status
echo "ExternalSecrets:"
kubectl get externalsecret -n "$NAMESPACE" -o json 2>/dev/null | jq -r '.items[] | "  \(.metadata.name): status=\(.status.conditions[]? | select(.type=="Ready") | .status // "none"), message=\(.status.conditions[]? | select(.type=="Ready") | .message // "none")"' 2>/dev/null || echo "   (No ExternalSecrets or jq not available)"

echo ""
echo "3. Checking what ArgoCD sees (from Application resource tree)..."
echo ""

if command -v argocd &> /dev/null; then
  echo "Resource health from ArgoCD Application:"
  argocd app get health-check-test-resources --server c0ks99cuw814yfdu.cd.akuity.cloud -o json 2>/dev/null | jq -r '.status.resources[]? | select(.kind == "ExternalSecret" or .kind == "ScaledObject") | "  \(.kind)/\(.name): Health=\(.health.status // "Unknown"), Sync=\(.status // "Unknown")"' 2>/dev/null || echo "   (Could not get Application status)"
else
  echo "   Install argocd CLI to check Application status"
fi

echo ""
echo "4. Key Issue: Resources need status conditions in the LIVE resource"
echo ""
echo "   ArgoCD evaluates health based on the LIVE resource status, not the desired state."
echo "   Your test resources have status in the YAML, but if the live resource doesn't"
echo "   have matching status, ArgoCD can't evaluate health correctly."
echo ""
echo "   To fix: After resources are synced, you may need to manually add status:"
echo "   kubectl patch externalsecret test-externalsecret-ready -n $NAMESPACE --type='merge' -p='{\"status\":{\"conditions\":[{\"type\":\"Ready\",\"status\":\"True\",\"message\":\"ExternalSecret is ready\"}]}}'"
echo ""

echo "5. For ScaledObjects - they need the Deployment to exist first"
echo ""
echo "   The Deployment must be created before ScaledObjects can sync."
echo "   Add test-deployment.yaml to your Git repo and ensure it syncs first."
echo ""
