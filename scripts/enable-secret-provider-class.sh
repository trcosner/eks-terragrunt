#!/bin/bash

# Enable SecretProviderClass for Dev and Staging
# This script implements the quick win from NextSteps.md

set -e

echo "🔐 Enabling SecretProviderClass for EKS clusters..."

# Function to enable SecretProviderClass for an environment
enable_secret_provider_class() {
    local env=$1
    echo "📝 Enabling SecretProviderClass for $env environment..."
    
    cd "infrastructure/$env/kubernetes-addons/"
    
    # Check if terragrunt.hcl exists
    if [ ! -f "terragrunt.hcl" ]; then
        echo "❌ Error: terragrunt.hcl not found in $env/kubernetes-addons/"
        return 1
    fi
    
    # Update the terragrunt.hcl file to enable SecretProviderClass
    if grep -q "create_example_secret_provider_class" terragrunt.hcl; then
        sed -i '' 's/create_example_secret_provider_class = false/create_example_secret_provider_class = true/' terragrunt.hcl
        echo "✅ Updated existing create_example_secret_provider_class setting"
    else
        # Add the setting if it doesn't exist
        sed -i '' '/secrets_manager_policy_arn/a\
  create_example_secret_provider_class = true' terragrunt.hcl
        echo "✅ Added create_example_secret_provider_class = true"
    fi
    
    echo "🚀 Applying Terragrunt changes for $env..."
    terragrunt apply -auto-approve
    
    echo "✅ SecretProviderClass enabled for $env environment"
    cd - > /dev/null
}

# Check if we're in the correct directory
if [ ! -d "infrastructure" ]; then
    echo "❌ Error: This script must be run from the project root directory"
    exit 1
fi

# Enable for dev environment
echo "🔧 Processing dev environment..."
enable_secret_provider_class "dev"

# Enable for staging environment
echo "🔧 Processing staging environment..."
enable_secret_provider_class "staging"

echo ""
echo "🎉 SecretProviderClass has been enabled for both dev and staging environments!"
echo ""
echo "📋 Next steps:"
echo "1. Verify the SecretProviderClass is working:"
echo "   kubectl get secretproviderclass -n default"
echo ""
echo "2. Test with the example application:"
echo "   kubectl apply -f examples/secure-production-app.yaml"
echo ""
echo "3. Check the secrets are mounted:"
echo "   kubectl exec -it <pod-name> -- ls -la /mnt/secrets-store/"
echo ""
echo "🔍 For more details, see: docs/diagrams/infrastructure-status.md"
