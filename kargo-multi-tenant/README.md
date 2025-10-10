# Kargo Multi-Tenant with ApplicationSet

One Git repo (`testing-grounds`), one branch per Kargo project. ApplicationSets auto-create Applications.

## Architecture

```
Platform Cluster (Labs)
├─ Argo CD (manages platform via GitOps)
├─ Kargo Agents (isolated per team namespace)
│  ├─ team-alpha namespace (projects: webapp, api)
│  └─ team-beta namespace (projects: mobile)
└─ Verification Jobs (workload identity → app clusters)

App Clusters (Destination)
└─ No Kargo agents, deployment via Jenkins
```

## Quick Start

### 1. Bootstrap (one-time)

```bash
kubectl apply -f kargo-multi-tenant/platform-cluster/argocd-bootstrap.yaml
kubectl get application kargo-platform -n akuity -w  # Wait for Synced
```

### 2. Create Team Branch

```bash
git checkout -b team-alpha-project-webapp
mkdir -p kargo-manifests
cp kargo-multi-tenant/team-alpha/project-webapp/kargo-manifests/* kargo-manifests/
git add kargo-manifests/
git commit -m "Add webapp Kargo project"
git push origin team-alpha-project-webapp
```

### 3. Verify

```bash
# ApplicationSet creates Application
kubectl get applications -n akuity | grep team-alpha

# Kargo resources synced
kubectl get projects,warehouses,stages -n kargo-team-alpha-team-alpha-project-webapp

# Freight detected
kubectl get freight -n kargo-team-alpha-team-alpha-project-webapp
```

## Structure

```
testing-grounds/
├── main branch
│   └── kargo-multi-tenant/platform-cluster/
│       ├── argocd-bootstrap.yaml         (GitOps entry point)
│       ├── applicationset-team-*.yaml    (hardcoded projects ✅)
│       ├── appproject-team-*.yaml        (SSO + RBAC)
│       └── kargo-namespace-team-*.yaml   (workload identity)
│
└── team branches (created by teams)
    ├── team-alpha-project-webapp → kargo-manifests/
    ├── team-alpha-project-api → kargo-manifests/
    └── team-beta-project-mobile → kargo-manifests/
```

## Images Used (public, no auth)

- **Team Alpha Webapp**: `public.ecr.aws/nginx/nginx:^1.26.0`
- **Team Alpha API**: `redis:^7.0.0`
- **Team Beta Mobile**: `postgres:^16.0.0`

## Key Features

✅ **Hardcoded Projects** - Each ApplicationSet has project hardcoded (secure)  
✅ **GitOps** - Bootstrap once, then everything via Git commits  
✅ **Auto-Discovery** - ApplicationSet detects new branches  
✅ **Team Isolation** - Separate namespaces, SSO groups  
✅ **Workload Identity** - GCP Secret Manager for secrets  
✅ **Verification Jobs** - Check app cluster health (egress only)  
✅ **Multi-Project** - Multiple projects per team  

## How It Works

```
1. Push image → public.ecr.aws/nginx/nginx:1.26.1
2. Warehouse detects → creates Freight
3. Auto-promote to dev → git-push to argocd-example-apps
4. Jenkins deploys → app cluster
5. Verification job → checks pods ready (via kubeconfig from GCP)
6. Manual promote to prod → repeat
```

## GCP Workload Identity (optional)

See `platform-cluster/gcp-workload-identity-setup.yaml` for commands to:

- Create GCP service accounts
- Bind to K8s service accounts
- Store app cluster kubeconfigs in Secret Manager
- Store Git credentials in Secret Manager

Verification jobs use workload identity to access secrets and app clusters.

## Adding Teams

Just add to `platform-cluster/` (commit to main):

- `applicationset-team-gamma.yaml` (copy team-alpha, change to team-gamma)
- `appproject-team-gamma.yaml`
- `kargo-namespace-team-gamma.yaml`

Argo CD syncs automatically.
