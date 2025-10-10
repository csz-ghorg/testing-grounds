#!/bin/bash
# GitOps Bootstrap - ONE TIME ONLY
# Everything else managed through Git commits

echo "╔════════════════════════════════════════════════════╗"
echo "║  Kargo Multi-Tenant GitOps Bootstrap              ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

echo "Prerequisites:"
echo "  ✓ Platform resources committed to testing-grounds main branch"
echo "  ✓ Path: kargo-multi-tenant/platform-cluster/"
echo ""

read -p "Commit platform resources to main branch? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Committing platform resources..."
    cd ../../
    git add kargo-multi-tenant/platform-cluster/
    git commit -m "Add Kargo multi-tenant platform resources"
    git push origin main
    cd kargo-multi-tenant
    echo "✓ Committed to main branch"
    echo ""
fi

echo "Applying bootstrap Application (GitOps entry point)..."
kubectl apply -f platform-cluster/argocd-bootstrap.yaml

echo ""
echo "✓ Bootstrap complete!"
echo ""
echo "Argo CD Application 'kargo-platform' will now sync:"
echo "  • Kargo namespaces (team-alpha, team-beta)"
echo "  • AppProjects (team-alpha, team-beta)"  
echo "  • ApplicationSets (kargo-team-alpha, kargo-team-beta)"
echo ""
echo "Watch sync:"
echo "  kubectl get application kargo-platform -n akuity -w"
echo ""
echo "══════════════════════════════════════════════════════"
echo "Next: Create team branches (see README.md)"
echo "══════════════════════════════════════════════════════"
