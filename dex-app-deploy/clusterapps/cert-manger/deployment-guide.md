# Complete SSL Certificate and Application Deployment Guide

## Quick Decision Matrix

| **Priority** | **Approach** | **Command** | **Timeline** |
|--------------|--------------|-------------|---------------|
| 🚀 **Get Started Fast** | HTTP-01 Challenge | `kubectl apply -f clusterissuer-http01.yaml` | 5 minutes |
| 🏢 **Production Ready** | Cross-Account DNS-01 | Coordinate with domain owner first | 1-2 days |
| 🔬 **Testing/Development** | Self-Signed Certs | Create local CA | Immediate |

---

## Option A: Quick Start with HTTP-01 (RECOMMENDED FOR IMMEDIATE DEPLOYMENT)

### Step 1: Deploy HTTP-01 ClusterIssuer
```bash
kubectl apply -f clusterissuer-http01.yaml
```

### Step 2: Create Individual Certificates
```bash
kubectl apply -f certificates-multi-option.yaml
```

### Step 3: Monitor Certificate Issuance
```bash
# Watch certificate status
kubectl get certificates -n istio-ingress -w

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager -f
```

### Step 4: Deploy Istio Gateway
```bash
kubectl apply -f ../istio-ingress/gateways-complete.yaml
```

### Step 5: Update DNS Records
Create A records in Route53 (domain owner account 494106420639):
```
auth.dev.mocafi.com      A    <NLB-IP>
dex-portal.dev.mocafi.com A    <NLB-IP>
wep-admin.dev.mocafi.com  A    <NLB-IP>
```

Get NLB IP:
```bash
kubectl get svc -n istio-ingress istio-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

## Option B: Production Setup with Cross-Account DNS-01

### Prerequisites
- Coordination with domain owner (Account 494106420639)
- Cross-account IAM role setup

### Step 1: Domain Owner Creates Cross-Account Role
**Run in domain owner account (494106420639):**

```bash
# Create trust policy
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

# Create role
aws iam create-role \
    --role-name CertManagerCrossAccountAccess \
    --assume-role-policy-document file://cross-account-trust-policy.json

# Attach permissions
aws iam attach-role-policy \
    --role-name CertManagerCrossAccountAccess \
    --policy-arn arn:aws:iam::aws:policy/Route53FullAccess

# Get role ARN (send this to EKS team)
aws iam get-role --role-name CertManagerCrossAccountAccess --query 'Role.Arn'
```

### Step 2: Deploy Cross-Account ClusterIssuer
**Run in your EKS account:**
```bash
kubectl apply -f clusterissuer-cross-account.yaml
```

### Step 3: Create Wildcard Certificate
```bash
# Apply only the wildcard certificate section
kubectl apply -f - << EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: dev-wildcard-cert-dns01
  namespace: istio-ingress
spec:
  secretName: dev-wildcard-cert-dns01
  revisionHistoryLimit: 1
  privateKey:
    rotationPolicy: Always
  commonName: "*.dev.mocafi.com"
  dnsNames:
    - "*.dev.mocafi.com"
    - "dev.mocafi.com"
  usages:
    - digital signature
    - key encipherment
    - server auth
  issuerRef:
    name: letsencrypt-dns01-cross-account
    kind: ClusterIssuer
EOF
```

### Step 4: Deploy Wildcard Gateway
```bash
# Apply only the wildcard gateway section
kubectl apply -f - << EOF
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: dex-gateway-wildcard
  namespace: istio-ingress
spec:
  selector:
    istio: ingress
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "dev.mocafi.com"
    - "*.dev.mocafi.com"
    tls:
      httpsRedirect: true
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "dev.mocafi.com"
    - "*.dev.mocafi.com"
    tls:
      mode: SIMPLE
      credentialName: dev-wildcard-cert-dns01
EOF
```

---

## Application Deployment Architecture

### Planned Services
1. **auth.dev.mocafi.com** - Authentication/Authorization API
2. **dex-portal.dev.mocafi.com** - Frontend Portal Application
3. **wep-admin.dev.mocafi.com** - Admin Dashboard

### Service Mesh Benefits with Istio
- 🔒 **mTLS**: Automatic encryption between services
- 📊 **Observability**: Kiali, Jaeger, Prometheus integration
- 🌊 **Traffic Management**: Canary deployments, circuit breakers
- 🚦 **Security Policies**: AuthN/AuthZ, rate limiting

---

## Monitoring and Troubleshooting

### Check Certificate Status
```bash
# List all certificates
kubectl get certificates -A

# Describe specific certificate
kubectl describe certificate <cert-name> -n istio-ingress

# Check certificate events
kubectl get events -n istio-ingress --field-selector involvedObject.kind=Certificate
```

### Debug cert-manager
```bash
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager --tail=50

# Check certificate requests
kubectl get certificaterequests -n istio-ingress

# Check ACME orders (DNS-01 only)
kubectl get orders -n istio-ingress

# Check challenges
kubectl get challenges -n istio-ingress
```

### Test SSL Certificates
```bash
# Test certificate with openssl
echo | openssl s_client -connect auth.dev.mocafi.com:443 -servername auth.dev.mocafi.com 2>/dev/null | openssl x509 -noout -dates

# Check certificate chain
curl -vI https://auth.dev.mocafi.com
```

### Access Istio Dashboards
```bash
# Kiali (Service Mesh Dashboard)
kubectl port-forward -n istio-system svc/kiali 20001:20001
# Open: http://localhost:20001

# Prometheus (Metrics)
kubectl port-forward -n istio-system svc/prometheus 9090:9090
# Open: http://localhost:9090
```

---

## Next Steps After SSL Setup

1. **Deploy Your Applications**
   - Create Kubernetes deployments for your services
   - Ensure services are properly labeled for Istio injection

2. **Configure Service-to-Service Communication**
   - Set up DestinationRules for load balancing
   - Configure VirtualServices for advanced routing

3. **Implement Security Policies**
   - AuthorizationPolicies for access control
   - PeerAuthentication for mTLS requirements

4. **Set Up Monitoring**
   - Configure Prometheus scraping
   - Set up Grafana dashboards
   - Configure alerting rules

---

## Common Issues and Solutions

### Certificate Stuck in "Issuing" State
- **HTTP-01**: Check if LoadBalancer is accessible from internet
- **DNS-01**: Verify Route53 permissions and hosted zone access
- **General**: Check cert-manager logs for specific errors

### Gateway Not Working
- Verify certificate secret exists: `kubectl get secrets -n istio-ingress`
- Check Istio proxy logs: `kubectl logs -n istio-ingress <istio-proxy-pod>`
- Ensure selector matches: `istio: ingress`

### DNS Resolution Issues
- Verify A records point to correct LoadBalancer
- Test DNS resolution: `nslookup auth.dev.mocafi.com`
- Check propagation: `dig auth.dev.mocafi.com @8.8.8.8`

---

Choose your path and let's get your applications secured with SSL! 🚀

