#!/bin/bash
# Apply status conditions to live resources so ArgoCD can evaluate health
# This simulates what the controllers would set

set -e

NAMESPACE="check-testing"

echo "=== Applying Status to Resources for Health Check Testing ==="
echo ""

echo "1. Applying status to ExternalSecrets..."
echo ""

# test-externalsecret-ready - should be Healthy
kubectl patch externalsecret test-externalsecret-ready -n "$NAMESPACE" --type='merge' -p='{
  "status": {
    "conditions": [
      {
        "type": "Ready",
        "status": "True",
        "message": "ExternalSecret is ready",
        "lastTransitionTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
      }
    ],
    "refreshTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }
}' 2>/dev/null && echo "   ✓ test-externalsecret-ready status applied" || echo "   ⚠️  Could not apply status (resource may not exist)"

# test-externalsecret-degraded - should be Degraded
kubectl patch externalsecret test-externalsecret-degraded -n "$NAMESPACE" --type='merge' -p='{
  "status": {
    "conditions": [
      {
        "type": "Ready",
        "status": "False",
        "message": "ExternalSecret is not ready - failed to fetch secret",
        "lastTransitionTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
      }
    ],
    "refreshTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }
}' 2>/dev/null && echo "   ✓ test-externalsecret-degraded status applied" || echo "   ⚠️  Could not apply status (resource may not exist)"

# test-externalsecret-progressing - no status (should stay Progressing)
echo "   ℹ️  test-externalsecret-progressing - leaving without status (should show Progressing)"

echo ""
echo "2. Applying status to ScaledObjects (after Deployment exists)..."
echo ""

# First check if Deployment exists
if kubectl get deployment test-deployment -n "$NAMESPACE" &>/dev/null; then
  echo "   ✓ Deployment exists, applying ScaledObject status..."
  
  # test-scaledobject - should be Healthy
  kubectl patch scaledobject test-scaledobject -n "$NAMESPACE" --type='merge' -p='{
    "status": {
      "conditions": [
        {
          "type": "Ready",
          "status": "True",
          "message": "ScaledObject is ready",
          "lastTransitionTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        },
        {
          "type": "Paused",
          "status": "False",
          "lastTransitionTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        },
        {
          "type": "Fallback",
          "status": "False",
          "lastTransitionTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }
      ],
      "health": {
        "numberOfFailures": 0
      }
    }
  }' 2>/dev/null && echo "   ✓ test-scaledobject status applied" || echo "   ⚠️  Could not apply status"
  
  # test-scaledobject-degraded - should be Healthy (your script treats degraded as healthy)
  kubectl patch scaledobject test-scaledobject-degraded -n "$NAMESPACE" --type='merge' -p='{
    "status": {
      "conditions": [
        {
          "type": "Ready",
          "status": "False",
          "message": "ScaledObject is not ready",
          "lastTransitionTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        },
        {
          "type": "Paused",
          "status": "False",
          "lastTransitionTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        },
        {
          "type": "Fallback",
          "status": "False",
          "lastTransitionTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }
      ]
    }
  }' 2>/dev/null && echo "   ✓ test-scaledobject-degraded status applied" || echo "   ⚠️  Could not apply status"
  
  # test-scaledobject-suspended - should be Suspended
  kubectl patch scaledobject test-scaledobject-suspended -n "$NAMESPACE" --type='merge' -p='{
    "status": {
      "conditions": [
        {
          "type": "Ready",
          "status": "True",
          "message": "ScaledObject is ready",
          "lastTransitionTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        },
        {
          "type": "Paused",
          "status": "True",
          "message": "ScaledObject is paused",
          "lastTransitionTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        },
        {
          "type": "Fallback",
          "status": "False",
          "lastTransitionTime": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }
      ]
    }
  }' 2>/dev/null && echo "   ✓ test-scaledobject-suspended status applied" || echo "   ⚠️  Could not apply status"
  
  # test-scaledobject-progressing - no status (should stay Progressing)
  echo "   ℹ️  test-scaledobject-progressing - leaving without status (should show Progressing)"
else
  echo "   ⚠️  Deployment test-deployment not found. ScaledObjects cannot sync without it."
  echo "   Create the Deployment first, then ScaledObjects can sync."
fi

echo ""
echo "3. Waiting for ArgoCD to re-evaluate health (10 seconds)..."
sleep 10

echo ""
echo "=== Status Applied ==="
echo ""
echo "Now check ArgoCD Application to see if health status is correct:"
echo "  argocd app get health-check-test-resources --server c0ks99cuw814yfdu.cd.akuity.cloud"
echo ""
echo "Expected health status:"
echo "  - test-externalsecret-ready → Healthy"
echo "  - test-externalsecret-degraded → Degraded"
echo "  - test-externalsecret-progressing → Progressing"
echo "  - test-scaledobject → Healthy"
echo "  - test-scaledobject-degraded → Healthy (your script logic)"
echo "  - test-scaledobject-suspended → Suspended"
echo "  - test-scaledobject-progressing → Progressing"
echo ""
