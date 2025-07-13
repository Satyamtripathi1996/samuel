# SSL Certificate Options for Multi-Application Deployment

## Current Situation
- Domain `mocafi.com` is managed in AWS Account: 494106420639
- EKS cluster is in AWS Account: 750014327084
- Planning to deploy: Backend API, Frontend, etc.
- Current private hosted zone in EKS account won't work with Let's Encrypt

## Option 1: Cross-Account Route 53 Access (RECOMMENDED)

### Pros
✅ Supports wildcard certificates (`*.dev.mocafi.com`)
✅ Works with existing private hosted zones
✅ Most flexible for multiple subdomains
✅ Centralized DNS management
✅ Best for production environments

### Cons
❌ Requires coordination with domain owner
❌ Cross-account IAM setup complexity
❌ Dependency on another AWS account

### Setup Steps

#### In Domain Owner Account (494106420639)

1. **Create Cross-Account Role**
```bash
# Create trust policy for your EKS account
cat > cross-account-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::750014327084:role/cert-manager-route53"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
    --role-name CertManagerCrossAccountAccess \
    --assume-role-policy-document file://cross-account-trust-policy.json

# Attach Route53 permissions
aws iam attach-role-policy \
    --role-name CertManagerCrossAccountAccess \
    --policy-arn arn:aws:iam::aws:policy/Route53FullAccess
```

2. **ClusterIssuer Configuration**
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns01-cross-account
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: api-development@mocafi.com
    privateKeySecretRef:
      name: letsencrypt-dns01-cross-account-private-key
    solvers:
    - dns01:
        route53:
          region: us-east-1
          role: arn:aws:iam::494106420639:role/CertManagerCrossAccountAccess
          auth:
            kubernetes:
              serviceAccountRef:
                name: cert-manager-acme-dns01-route53
```

---

## Option 2: HTTP-01 Challenge (SIMPLE)

### Pros
✅ No DNS coordination needed
✅ Works immediately
✅ Simple setup
✅ Good for individual domains

### Cons
❌ No wildcard certificate support
❌ Need separate cert for each subdomain
❌ Requires public HTTP access
❌ More certificates to manage

### Setup
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-http01
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: api-development@mocafi.com
    privateKeySecretRef:
      name: letsencrypt-http01-private-key
    solvers:
    - http01:
        ingress:
          ingressTemplate:
            metadata:
              annotations:
                kubernetes.io/ingress.class: istio
```

---

## Option 3: Public Subdomain Delegation (HYBRID)

### Concept
Create a public subdomain (e.g., `k8s.dev.mocafi.com`) delegated to your account.

### Pros
✅ Independent DNS management
✅ Supports wildcards for delegated zone
✅ No ongoing cross-account dependency
✅ Good separation of concerns

### Cons
❌ Requires one-time domain owner setup
❌ Different subdomain structure
❌ Limited to delegated zone

### Setup Steps

1. **In Domain Owner Account**: Create NS records for `k8s.dev.mocafi.com`
2. **In Your Account**: Create public hosted zone for `k8s.dev.mocafi.com`
3. **Use domains like**: `api.k8s.dev.mocafi.com`, `app.k8s.dev.mocafi.com`

---

## Option 4: Self-Signed + Private CA (DEVELOPMENT)

### Pros
✅ No external dependencies
✅ Full control
✅ Works immediately
✅ Good for development/testing

### Cons
❌ Browser warnings
❌ Not trusted by default
❌ Manual certificate distribution
❌ Not suitable for production

---

## Option 5: External Certificate Import

### Concept
Obtain certificates externally and import them as Kubernetes secrets.

### Pros
✅ Use any certificate provider
✅ Works with any domain setup
✅ No cert-manager complexity

### Cons
❌ Manual certificate management
❌ No automatic renewal
❌ Operational overhead

---

## Recommendation Matrix

| Use Case | Recommended Option | Reason |
|----------|-------------------|--------|
| Production Multi-App | Option 1 (Cross-Account) | Wildcard support, scalable |
| Quick Development | Option 2 (HTTP-01) | Simple, immediate |
| Independent Team | Option 3 (Subdomain Delegation) | Autonomous operation |
| Local Development | Option 4 (Self-Signed) | No external dependencies |
| Existing Cert Process | Option 5 (Import) | Fits existing workflow |

---

## Next Steps

### For Production (Option 1 - Cross-Account)
1. Coordinate with domain owner for cross-account role
2. Test with staging Let's Encrypt first
3. Deploy wildcard certificate
4. Configure Istio Gateway with TLS

### For Quick Start (Option 2 - HTTP-01)
1. Deploy HTTP-01 ClusterIssuer
2. Create individual certificates per service
3. Configure Istio Gateway with multiple TLS blocks

### Application Architecture Planning
- `api.dev.mocafi.com` → Backend API
- `app.dev.mocafi.com` → Frontend Application
- `admin.dev.mocafi.com` → Admin Dashboard
- `docs.dev.mocafi.com` → Documentation

Choose the option that best fits your:
- **Timeline**: How quickly you need SSL
- **Control**: How much domain control you have
- **Scale**: How many services you'll deploy
- **Environment**: Development vs Production

