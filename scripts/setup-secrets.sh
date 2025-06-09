#!/bin/bash

# AWS Secrets Manager Setup Script
# Creates example secrets for your EKS applications

set -e

# Configuration
ENV=${1:-dev}
REGION=${AWS_REGION:-us-west-2}

if [ -z "$ENV" ]; then
    echo "Usage: $0 <environment> [region]"
    echo "Example: $0 dev us-west-2"
    exit 1
fi

echo "🔐 Setting up AWS Secrets Manager for environment: $ENV"
echo "📍 Region: $REGION"

# Function to create or update secret
create_or_update_secret() {
    local secret_name=$1
    local secret_value=$2
    local description=$3
    
    echo "Creating/updating secret: $secret_name"
    
    # Check if secret exists
    if aws secretsmanager describe-secret --secret-id "$secret_name" --region "$REGION" >/dev/null 2>&1; then
        echo "  ↪ Secret exists, updating..."
        aws secretsmanager update-secret \
            --secret-id "$secret_name" \
            --secret-string "$secret_value" \
            --region "$REGION" \
            --description "$description"
    else
        echo "  ↪ Creating new secret..."
        aws secretsmanager create-secret \
            --name "$secret_name" \
            --secret-string "$secret_value" \
            --region "$REGION" \
            --description "$description"
    fi
    
    echo "  ✅ Secret $secret_name ready"
}

# Create database password secret
DB_PASSWORD=$(openssl rand -base64 32)
create_or_update_secret \
    "$ENV/database/password" \
    "{\"password\":\"$DB_PASSWORD\"}" \
    "Database password for $ENV environment"

# Create API keys secret
API_KEY=$(uuidgen | tr '[:upper:]' '[:lower:]')
JWT_SECRET=$(openssl rand -base64 64)
create_or_update_secret \
    "$ENV/api/keys" \
    "{\"api_key\":\"$API_KEY\",\"jwt_secret\":\"$JWT_SECRET\"}" \
    "API keys and JWT secret for $ENV environment"

# Create application configuration secret
create_or_update_secret \
    "$ENV/app/config" \
    "{\"redis_url\":\"redis://redis-cluster:6379\",\"db_host\":\"postgres.internal\",\"debug\":\"false\"}" \
    "Application configuration for $ENV environment"

echo ""
echo "🎉 Secrets setup complete!"
echo ""
echo "📋 Created secrets:"
echo "  • $ENV/database/password     - Database credentials"
echo "  • $ENV/api/keys             - API keys and JWT secret"  
echo "  • $ENV/app/config           - Application configuration"
echo ""
echo "🔧 To use these secrets in your Kubernetes applications:"
echo "1. Deploy the kubernetes-addons with secrets management enabled"
echo "2. Use the SecretProviderClass 'app-secrets' in your pod specs"
echo "3. Mount secrets as volumes: /mnt/secrets/"
echo ""
echo "📖 Example usage:"
echo "  kubectl apply -f examples/secure-production-app.yaml"
echo ""
echo "🔍 Verify secrets:"
echo "  aws secretsmanager list-secrets --region $REGION | grep $ENV"
