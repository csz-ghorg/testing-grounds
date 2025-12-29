# Pattern 2: ApplicationSet with Git Generator (Platform-Managed)

This pattern has the platform team manage the ApplicationSet. Tenants commit application source code (Kustomize/Helm) to directories in Git. The ApplicationSet discovers and generates Applications automatically.

## How It Works

1. Tenant commits application source code (Kustomize/Helm) to Git
2. ApplicationSet discovers directories and generates Applications
3. Tenants don't manage Application manifests directly
4. Platform controls ApplicationSet configuration

## Benefits

- Simpler for tenants - they only manage application source code
- Automatic discovery - new services are automatically picked up
- Platform control - consistent Application configuration
- Less error-prone - tenants can't misconfigure Application specs
- Scalable - easy to add new services

## Trade-offs

- Less tenant flexibility - Application structure is fixed
- Platform dependency - changes require platform team
- Less control - tenants can't customize Application settings
- Fixed structure - must follow directory conventions

## Directory Structure

```
pattern-2-git-generator/
├── README.md                          # This file
├── platform-managed/                  # Platform-managed ApplicationSet
│   └── team-alpha-services-appset.yaml
└── tenant-examples/                   # Example tenant Git repo structure
    └── team-alpha-services/          # Simulated team-alpha service repo
        └── services/
            └── frontend/             # Service discovered by ApplicationSet
                └── kustomization.yaml
```

## When to Use

Best for teams that want simplicity and automatic Application generation without managing Application manifests.

