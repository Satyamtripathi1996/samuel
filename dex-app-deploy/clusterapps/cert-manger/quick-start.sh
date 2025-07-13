#!/bin/bash

# Quick Start SSL Certificate Deployment
# This script sets up HTTP-01 certificates for immediate use

echo "🚀 Starting Quick SSL Certificate Deployment..."
echo "📋 This will set up individual certificates for each service using HTTP-01 challenge"
echo ""

# Check if we're in the right directory
if [[ ! -f "clusterissuer-http01.yaml" ]]; then
    echo "❌ Error: Please run this script from the cert-manger directory"
    exit 1
fi

# Get LoadBalancer endpoint
echo "🔍 Getting LoadBalancer endpoint..."
LB_ENDPOINT=$(kubectl get svc -n istio-ingress istio-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "📍 LoadBalancer: $LB_ENDPOINT"
echo ""

# Step 1: Deploy HTTP-01 ClusterIssuer
echo "📝 Step 1: Creating HTTP-01 ClusterIssuer..."
kubectl apply -f clusterissuer-http01.yaml
echo "✅ ClusterIssuer created"
echo ""

# Wait a moment for ClusterIssuer to be ready
echo "⏳ Waiting for ClusterIssuer to be ready..."
sleep 5

# Check ClusterIssuer status
echo "🔍 Checking ClusterIssuer status..."
kubectl get clusterissuer letsencrypt-http01
echo ""

# Step 2: Create certificates (HTTP-01 sections only)
echo "📝 Step 2: Creating individual certificates..."
echo "Creating certificate for auth.dev.mocafi.com..."
kubectl apply -f - << 'EOF'
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: auth-dev-mocafi-cert
  namespace: istio-ingress
spec:
  secretName: auth-dev-mocafi-cert
  revisionHistoryLimit: 1
  privateKey:
    rotationPolicy: Always
  commonName: "auth.dev.mocafi.com"
  dnsNames:
    - "auth.dev.mocafi.com"
  usages:
    - digital signature
    - key encipherment
    - server auth
  issuerRef:
    name: letsencrypt-http01
    kind: ClusterIssuer
EOF

echo "Creating certificate for dex-portal.dev.mocafi.com..."
kubectl apply -f - << 'EOF'
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: dex-portal-dev-mocafi-cert
  namespace: istio-ingress
spec:
  secretName: dex-portal-dev-mocafi-cert
  revisionHistoryLimit: 1
  privateKey:
    rotationPolicy: Always
  commonName: "dex-portal.dev.mocafi.com"
  dnsNames:
    - "dex-portal.dev.mocafi.com"
  usages:
    - digital signature
    - key encipherment
    - server auth
  issuerRef:
    name: letsencrypt-http01
    kind: ClusterIssuer
EOF

echo "Creating certificate for wep-admin.dev.mocafi.com..."
kubectl apply -f - << 'EOF'
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wep-admin-dev-mocafi-cert
  namespace: istio-ingress
spec:
  secretName: wep-admin-dev-mocafi-cert
  revisionHistoryLimit: 1
  privateKey:
    rotationPolicy: Always
  commonName: "wep-admin.dev.mocafi.com"
  dnsNames:
    - "wep-admin.dev.mocafi.com"
  usages:
    - digital signature
    - key encipherment
    - server auth
  issuerRef:
    name: letsencrypt-http01
    kind: ClusterIssuer
EOF

echo "✅ Certificates created"
echo ""

# Step 3: Deploy Istio Gateway for individual certificates
echo "📝 Step 3: Creating Istio Gateway..."
kubectl apply -f - << 'EOF'
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: dex-gateway-individual
  namespace: istio-ingress
spec:
  selector:
    istio: ingress
  servers:
  # HTTP server (redirects to HTTPS)
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "auth.dev.mocafi.com"
    - "dex-portal.dev.mocafi.com"
    - "wep-admin.dev.mocafi.com"
    tls:
      httpsRedirect: true
  # HTTPS for auth service
  - port:
      number: 443
      name: https-auth
      protocol: HTTPS
    hosts:
    - "auth.dev.mocafi.com"
    tls:
      mode: SIMPLE
      credentialName: auth-dev-mocafi-cert
  # HTTPS for dex-portal
  - port:
      number: 443
      name: https-dex-portal
      protocol: HTTPS
    hosts:
    - "dex-portal.dev.mocafi.com"
    tls:
      mode: SIMPLE
      credentialName: dex-portal-dev-mocafi-cert
  # HTTPS for wep-admin
  - port:
      number: 443
      name: https-wep-admin
      protocol: HTTPS
    hosts:
    - "wep-admin.dev.mocafi.com"
    tls:
      mode: SIMPLE
      credentialName: wep-admin-dev-mocafi-cert
EOF

echo "✅ Gateway created"
echo ""

# Step 4: Show status
echo "📊 Current Status:"
echo "Certificates:"
kubectl get certificates -n istio-ingress
echo ""
echo "Gateways:"
kubectl get gateways -n istio-ingress
echo ""

# Step 5: DNS Instructions
echo "📋 NEXT STEPS:"
echo ""
echo "1. 🌐 Create these DNS records in Route53 (Account 494106420639):"
echo "   auth.dev.mocafi.com      A    $LB_ENDPOINT"
echo "   dex-portal.dev.mocafi.com A    $LB_ENDPOINT"
echo "   wep-admin.dev.mocafi.com  A    $LB_ENDPOINT"
echo ""
echo "2. 👀 Monitor certificate issuance:"
echo "   kubectl get certificates -n istio-ingress -w"
echo ""
echo "3. 🔍 Check cert-manager logs if needed:"
echo "   kubectl logs -n cert-manager -l app=cert-manager -f"
echo ""
echo "4. 🧪 Test HTTP-01 challenge (after DNS propagation):"
echo "   curl -I http://auth.dev.mocafi.com/.well-known/acme-challenge/test"
echo ""
echo "5. 🚀 Deploy your applications and create VirtualServices to route traffic"
echo ""
echo "📚 For complete documentation, see: deployment-guide.md"
echo "🎯 For production setup with wildcards, see: ssl-certificate-options.md"
echo ""
echo "✨ SSL setup initiated! Certificates will be ready once DNS records are created and propagated."

