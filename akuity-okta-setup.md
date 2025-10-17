# Akuity ArgoCD + Okta SSO Setup Guide

Since you're using Akuity (managed ArgoCD), you need to configure RBAC through the Akuity platform, not Kubernetes manifests.

## 1. Akuity Dashboard Configuration

### Step 1: Configure Okta OIDC

1. Log into your Akuity dashboard
2. Go to **Settings** → **SSO Configuration**
3. Select **OpenID Connect (OIDC)**
4. Configure the following:

```
Provider Name: Okta
Issuer URL: https://your-okta-domain.okta.com/oauth2/default
Client ID: your-okta-client-id
Client Secret: your-okta-client-secret
Requested Scopes: openid,profile,email,groups
Requested ID Token Claims: {"groups": {"essential": true}}
```

### Step 2: Configure RBAC Policies

In the Akuity dashboard, go to **Settings** → **RBAC Configuration** and add this policy:

```csv
# Admin users - full access
p, role:admin, applications, *, */*, allow
p, role:admin, clusters, *, *, allow
p, role:admin, repositories, *, *, allow
p, role:admin, projects, *, *, allow
p, role:admin, certificates, *, *, allow
p, role:admin, accounts, *, *, allow
p, role:admin, gpgkeys, *, *, allow
p, role:admin, logs, *, *, allow
p, role:admin, exec, *, *, allow
p, role:admin, events, *, *, allow
p, role:admin, applicationSets, *, */*, allow

# Team Alpha - access to team-alpha projects and applications
p, role:team-alpha, applications, get, team-alpha/*, allow
p, role:team-alpha, applications, list, team-alpha/*, allow
p, role:team-alpha, applications, watch, team-alpha/*, allow
p, role:team-alpha, applications, sync, team-alpha/*, allow
p, role:team-alpha, applications, action/*, team-alpha/*, allow
p, role:team-alpha, projects, get, team-alpha, allow
p, role:team-alpha, projects, list, team-alpha, allow
p, role:team-alpha, projects, watch, team-alpha, allow
p, role:team-alpha, repositories, get, *, allow
p, role:team-alpha, repositories, list, *, allow
p, role:team-alpha, repositories, watch, *, allow
p, role:team-alpha, events, get, team-alpha/*, allow
p, role:team-alpha, events, list, team-alpha/*, allow
p, role:team-alpha, events, watch, team-alpha/*, allow
p, role:team-alpha, logs, get, team-alpha/*, allow
p, role:team-alpha, logs, list, team-alpha/*, allow
p, role:team-alpha, logs, watch, team-alpha/*, allow
p, role:team-alpha, exec, create, team-alpha/*, allow

# Team Beta - access to team-beta projects and applications
p, role:team-beta, applications, get, team-beta/*, allow
p, role:team-beta, applications, list, team-beta/*, allow
p, role:team-beta, applications, watch, team-beta/*, allow
p, role:team-beta, applications, sync, team-beta/*, allow
p, role:team-beta, applications, action/*, team-beta/*, allow
p, role:team-beta, projects, get, team-beta, allow
p, role:team-beta, projects, list, team-beta, allow
p, role:team-beta, projects, watch, team-beta, allow
p, role:team-beta, repositories, get, *, allow
p, role:team-beta, repositories, list, *, allow
p, role:team-beta, repositories, watch, *, allow
p, role:team-beta, events, get, team-beta/*, allow
p, role:team-beta, events, list, team-beta/*, allow
p, role:team-beta, events, watch, team-beta/*, allow
p, role:team-beta, logs, get, team-beta/*, allow
p, role:team-beta, logs, list, team-beta/*, allow
p, role:team-beta, logs, watch, team-beta/*, allow
p, role:team-beta, exec, create, team-beta/*, allow

# Group mappings - Okta groups to ArgoCD roles
g, okta-team-alpha, role:team-alpha
g, okta-team-beta, role:team-beta
g, okta-admins, role:admin
```

## 2. Okta Configuration

### Step 1: Create Groups in Okta

1. Go to **Directory** → **Groups** in Okta
2. Create these groups:
   - `okta-team-alpha`
   - `okta-team-beta`
   - `okta-admins`

### Step 2: Create OIDC Application

1. Go to **Applications** → **Applications** → **Create App Integration**
2. Choose **OIDC - OpenID Connect**
3. Choose **Web Application**
4. Configure:
   - **App integration name**: ArgoCD
   - **Grant types**: Authorization Code, Refresh Token
   - **Sign-in redirect URIs**: `https://your-akuity-instance.akuity.cloud/auth/callback`
   - **Sign-out redirect URIs**: `https://your-akuity-instance.akuity.cloud`
   - **Controlled access**: Assign groups `okta-team-alpha`, `okta-team-beta`, `okta-admins`

### Step 3: Configure Group Claims

1. In your OIDC app, go to **Sign-in options** → **OpenID Connect ID token**
2. Add group claims:
   - **Name**: `groups`
   - **Value**: `groups`
   - **Include in**: ID token

## 3. Kargo RBAC (Kubernetes)

The Kargo RBAC files I created (`kargo-team-alpha-rbac.yaml` and `kargo-team-beta-rbac.yaml`) can still be applied to your Kubernetes cluster since Kargo runs in your cluster:

```bash
kubectl apply -f kargo-team-alpha-rbac.yaml
kubectl apply -f kargo-team-beta-rbac.yaml
```

## 4. Testing the Setup

1. **Test SSO Login**: Try logging into ArgoCD via Okta SSO
2. **Test Team Isolation**:
   - Users in `okta-team-alpha` should only see `team-alpha` projects/applications
   - Users in `okta-team-beta` should only see `team-beta` projects/applications
   - Users in `okta-admins` should see everything

## 5. Troubleshooting

- **Check Akuity logs** for SSO authentication errors
- **Verify group claims** are being passed correctly in the ID token
- **Test with different user accounts** assigned to different Okta groups
- **Check ArgoCD RBAC logs** if users can't see expected resources

## Key Differences from Self-Managed ArgoCD

- ✅ **SSO Configuration**: Done in Akuity dashboard, not ConfigMaps
- ✅ **RBAC Policies**: Set in Akuity dashboard, not ConfigMaps
- ✅ **Kargo RBAC**: Still applied via kubectl (runs in your cluster)
- ✅ **No ConfigMap management**: Akuity handles ArgoCD configuration
