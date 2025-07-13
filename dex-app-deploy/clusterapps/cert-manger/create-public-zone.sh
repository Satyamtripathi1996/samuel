#!/bin/bash

# Script to create public hosted zone for Let's Encrypt

echo "🌍 Creating public hosted zone for dev.mocafi.com..."

# Create public hosted zone
echo "📝 Creating public hosted zone..."
aws route53 create-hosted-zone \
    --name dev.mocafi.com \
    --caller-reference "public-zone-$(date +%s)" \
    --hosted-zone-config Comment="Public zone for Let's Encrypt SSL certificates",PrivateZone=false

echo "✅ Public hosted zone created!"
echo "📋 Next steps:"
echo "1. Update your domain registrar to use the new nameservers"
echo "2. Wait for DNS propagation (up to 48 hours)"
echo "3. Retry certificate issuance"
echo ""
echo "To get the nameservers:"
echo "aws route53 list-hosted-zones --query 'HostedZones[?Name==\`dev.mocafi.com.\` && Config.PrivateZone==\`false\`].Id' --output text | xargs -I {} aws route53 get-hosted-zone --id {} --query 'DelegationSet.NameServers'"

