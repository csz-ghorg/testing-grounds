# Pattern 1: App-of-Apps for ApplicationSets and Applications

This pattern allows tenants to commit both ApplicationSet and Application manifests to their Git repo. A parent app-of-apps Application syncs these manifests into ArgoCD.

## How It Works

1. Tenant commits ApplicationSet/Application manifests to their Git repository
2. Parent app-of-apps Application syncs these manifests
3. ArgoCD application-controller creates ApplicationSet/Application resources
4. ArgoCD RBAC + AppProject restrictions enforce what tenants can create
5. ApplicationSet generates child Applications (if using generators)

## Enforcement

- **AppProject restrictions**: Tenants can only use their assigned project (team-alpha or team-beta)
- **ArgoCD RBAC**: Controls what tenants can do via UI/API/CLI
- **Git repo access**: Tenants can only commit to their own repos (enforced by Git permissions)

## Directory Structure

```
pattern-1-app-of-apps/
├── README.md                          # This file
├── parent-app-of-apps/               # Platform-managed parent applications
│   ├── team-alpha-app-of-apps.yaml   # Parent app for team-alpha
│   └── team-beta-app-of-apps.yaml    # Parent app for team-beta
└── tenant-examples/                   # Example tenant Git repo structures
    ├── team-alpha-gitops/            # Simulated team-alpha Git repo
    │   ├── applicationsets/
    │   │   └── services-appset.yaml
    │   └── applications/
    │       └── my-service.yaml
    └── team-beta-gitops/             # Simulated team-beta Git repo
        ├── applicationsets/
        │   └── services-appset.yaml
        └── applications/
            └── my-service.yaml
```

## Benefits

- Tenants have full control over their ApplicationSets and Applications
- All changes are Git-based and auditable
- ArgoCD RBAC and AppProject restrictions provide security boundaries
- No Kubernetes RBAC needed for tenants (all goes through ArgoCD)

## Security Considerations

1. **AppProject restrictions are critical**:
   - Each tenant should have their own AppProject
   - AppProject should restrict sourceRepos to tenant's repos only
   - AppProject should restrict destinations to tenant's namespaces/clusters

2. **ArgoCD RBAC should restrict**:
   - Which projects tenants can create Applications for
   - Which operations tenants can perform (sync, delete, etc.)

3. **Git repository access**:
   - Tenants should only have write access to their own repos
   - Platform team controls app-of-apps Applications

