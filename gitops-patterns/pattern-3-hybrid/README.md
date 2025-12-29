# Pattern 3: Hybrid - Tenants Manage ApplicationSets, ApplicationSet Generates Applications

This pattern allows tenants to commit ApplicationSet manifests to Git. App-of-apps syncs them. ApplicationSets then generate Applications automatically.

## How It Works

1. Tenant commits ApplicationSet manifest to their Git repo
2. Parent app-of-apps Application syncs the ApplicationSet
3. ApplicationSet generates Applications based on its generators
4. Tenants have control over ApplicationSet configuration (generators, templates)
5. Applications are generated automatically from ApplicationSet

## Benefits

- Balanced control - tenants control ApplicationSet, automation generates Applications
- Automation - Applications generated automatically, less repetitive
- Flexibility in generators - tenants can use different generator types
- Scalable - easy to add new services via generators
- Less repetitive - don't need to create individual Application manifests

## Trade-offs

- Moderate complexity - tenants need to understand ApplicationSets
- Two-step process - ApplicationSet → Applications
- Generator limitations - constrained by ApplicationSet generator capabilities
- Harder debugging - need to understand ApplicationSet generation logic

## Directory Structure

```
pattern-3-hybrid/
├── README.md                          # This file
├── parent-app-of-apps/               # Platform-managed parent applications
│   ├── team-alpha-app-of-apps.yaml
│   └── team-beta-app-of-apps.yaml
└── tenant-examples/                   # Example tenant Git repo structures
    ├── team-alpha-gitops/            # Simulated team-alpha Git repo
    │   └── applicationsets/
    │       └── services-appset.yaml
    └── team-beta-gitops/             # Simulated team-beta Git repo
        └── applicationsets/
            └── services-appset.yaml
```

## When to Use

Best for teams that want automation with some control over Application generation, but don't want to manage individual Application manifests.

