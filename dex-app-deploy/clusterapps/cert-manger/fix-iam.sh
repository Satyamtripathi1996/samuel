#!/bin/bash

# Script to fix cert-manager IAM configuration

echo "🔧 Fixing cert-manager IAM configuration..."

# Variables
ACCOUNT_ID="750014327084"
CLUSTER_NAME="dex-backend-us-east-1-eks"
REGION="us-east-1"
POLICY_NAME="CertManagerRoute53Policy"
ROLE_NAME="cert-manager-route53"
NAMESPACE="cert-manager"
SERVICE_ACCOUNT="cert-manager-acme-dns01-route53"

# Step 1: Create IAM Policy
echo "📝 Creating IAM policy..."
aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document file://cert-manager-route53-policy.json \
    --description "Policy for cert-manager to manage Route53 DNS records"

POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

# Step 2: Create Trust Policy for the Role
echo "📝 Creating trust policy..."
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/$(aws eks describe-cluster --name ${CLUSTER_NAME} --query 'cluster.identity.oidc.issuer' --output text | cut -d '/' -f 5)"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.${REGION}.amazonaws.com/id/$(aws eks describe-cluster --name ${CLUSTER_NAME} --query 'cluster.identity.oidc.issuer' --output text | cut -d '/' -f 5):sub": "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT}",
          "oidc.eks.${REGION}.amazonaws.com/id/$(aws eks describe-cluster --name ${CLUSTER_NAME} --query 'cluster.identity.oidc.issuer' --output text | cut -d '/' -f 5):aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF

# Step 3: Create IAM Role
echo "🔑 Creating IAM role..."
aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file://trust-policy.json \
    --description "Role for cert-manager to access Route53"

# Step 4: Attach Policy to Role
echo "🔗 Attaching policy to role..."
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn $POLICY_ARN

# Step 5: Update Kubernetes Service Account
echo "🔄 Updating Kubernetes service account..."
kubectl annotate serviceaccount $SERVICE_ACCOUNT \
    -n $NAMESPACE \
    eks.amazonaws.com/role-arn="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}" \
    --overwrite

# Step 6: Restart cert-manager to pick up new role
echo "🔄 Restarting cert-manager..."
kubectl rollout restart deployment/cert-manager -n cert-manager

echo "✅ IAM configuration updated!"
echo "🔍 Monitor the certificate status with: kubectl get certificates -n istio-ingress -w"

# Clean up temporary files
rm -f trust-policy.json

echo "📋 Next steps:"
echo "1. Wait for cert-manager to restart"
echo "2. Verify the hosted zone exists for dev.mocafi.com in Route 53"
echo "3. Check certificate status: kubectl describe certificate dev-wildcard-cert -n istio-ingress"

