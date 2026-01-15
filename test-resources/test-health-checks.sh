#!/bin/bash
# Test script to verify ArgoCD health check customizations are working
# This checks the Application resource tree to see if health checks are applied

set -e

APP_NAME="health-check-test-resources"
ARGOCD_SERVER="${ARGOCD_SERVER:-c0ks99cuw814yfdu.cd.akuity.cloud}"

echo "=== Testing ArgoCD Health Check Customizations ==="
echo ""

# Check if argocd CLI is available
if ! command -v argocd &> /dev/null; then
  echo "❌ ERROR: argocd CLI not found."
  echo "Install it from: https://argo-cd.readthedocs.io/en/stable/cli_installation/"
  exit 1
fi

echo "1. Checking Application status..."
echo ""
argocd app get "$APP_NAME" --server "$ARGOCD_SERVER" || {
  echo "❌ Application '$APP_NAME' not found."
  echo "Make sure the Application exists and is synced."
  exit 1
}

echo ""
echo "2. Checking resource health status in Application..."
echo ""
echo "Looking for KEDA ScaledObjects and ExternalSecrets in the resource tree:"
echo ""

# Get the application and extract resource health
argocd app get "$APP_NAME" --server "$ARGOCD_SERVER" -o json | jq -r '
  .status.resources[]? | 
  select(.kind == "ScaledObject" or .kind == "ExternalSecret") |
  "\(.kind)/\(.name): Health=\(.health.status // "Unknown"), Sync=\(.status // "Unknown")"
' 2>/dev/null || {
  echo "⚠️  No ScaledObjects or ExternalSecrets found in Application resource tree."
  echo ""
  echo "This could mean:"
  echo "  1. Resources haven't been synced yet"
  echo "  2. Application is pointing to wrong source"
  echo "  3. Resources are not in the Git repository"
  echo ""
  echo "Check Application source:"
  argocd app get "$APP_NAME" --server "$ARGOCD_SERVER" | grep -A 5 "Source:"
}

echo ""
echo "3. Expected vs Actual Health Status:"
echo ""
echo "If your health check customizations are working, you should see:"
echo ""
echo "KEDA ScaledObjects:"
echo "  - test-scaledobject → Healthy (Ready=True, Paused=False)"
echo "  - test-scaledobject-degraded → Healthy (your script treats degraded as healthy)"
echo "  - test-scaledobject-suspended → Suspended (Ready=True, Paused=True)"
echo "  - test-scaledobject-progressing → Progressing (no status)"
echo ""
echo "ExternalSecrets:"
echo "  - test-externalsecret-ready → Healthy (Ready=True)"
echo "  - test-externalsecret-degraded → Degraded (Ready=False)"
echo "  - test-externalsecret-progressing → Progressing (no status)"
echo ""

echo "=== Test Complete ==="
echo ""
echo "If health status doesn't match expected values, check:"
echo "  1. ConfigMap format: kubectl get configmap argocd-cm -n argocd -o yaml | grep -A 20 'Keda.sh_ScaledObject'"
echo "  2. Application controller logs: kubectl logs -n argocd deployment/argocd-application-controller | grep -i 'lua\|health'"
echo ""
