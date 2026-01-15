# Testing ArgoCD Health Check Customizations

To verify your health check customizations are working, ArgoCD must **manage** these resources through an Application.

## Quick Test

1. **Commit these test resources to a Git repository**

2. **Update the Application to point to your test resources:**
   ```bash
   argocd app set health-check-test-resources \
     --repo https://github.com/your-org/your-repo.git \
     --path test-resources \
     --revision main \
     --directory-recurse \
     --server c0ks99cuw814yfdu.cd.akuity.cloud
   ```

3. **Check the Application resource tree to see health status:**
   ```bash
   argocd app get health-check-test-resources --server c0ks99cuw814yfdu.cd.akuity.cloud
   ```

   Look for the KEDA ScaledObjects and ExternalSecrets in the resource tree. Their health status should match what your custom health check scripts expect.

## Expected Health Status

Based on your health check scripts:

**KEDA ScaledObjects:**
- `test-scaledobject` (Ready=True, Paused=False) → **Healthy**
- `test-scaledobject-degraded` (Ready=False) → **Healthy** (your script treats degraded as healthy)
- `test-scaledobject-suspended` (Ready=True, Paused=True) → **Suspended**
- `test-scaledobject-progressing` (no status) → **Progressing**

**ExternalSecrets:**
- `test-externalsecret-ready` (Ready=True) → **Healthy**
- `test-externalsecret-degraded` (Ready=False) → **Degraded**
- `test-externalsecret-progressing` (no status) → **Progressing**

## Verifying Health Checks Are Working

If ArgoCD is using your custom health checks:
- Health status in ArgoCD UI/CLI will match the expected values above
- The status will be different from ArgoCD's default behavior (which would likely show "Unknown" for custom resources)

If health checks are NOT working:
- Resources may show "Unknown" or "Missing" health status
- Or show incorrect status that doesn't match your script logic
