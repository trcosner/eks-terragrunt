#!/bin/bash

# Script to create comprehensive READMEs with terraform-docs generated content
# for all infrastructure, infrastructure-modules, and bootstrap directories

set -e

echo "🔄 Creating comprehensive READMEs with terraform-docs for all directories..."

# Function to create README for any directory with .tf files
create_terraform_readme() {
    local dir_path="$1"
    local readme_path="$dir_path/README.md"
    
    # Skip cache directories and .terraform directories
    if [[ "$dir_path" == *".terragrunt-cache"* ]] || [[ "$dir_path" == *".terraform"* ]]; then
        return
    fi
    
    # Skip if no .tf files exist
    tf_files=$(find "$dir_path" -maxdepth 1 -name "*.tf" -print -quit)
    if [ -z "$tf_files" ]; then
        return
    fi
    
    echo "📝 Creating README for: $dir_path"
    
    # Determine module/directory type and create appropriate header
    local dir_name=$(basename "$dir_path")
    local parent_dir=$(basename "$(dirname "$dir_path")")
    
    local header=""
    local description=""
    
    if [[ "$dir_path" == *"infrastructure-modules"* ]]; then
        # Infrastructure module
        case "$dir_name" in
            "eks") 
                header="# EKS Terraform Module"
                description="Creates an Amazon EKS cluster with managed node groups, IAM roles, and OIDC provider integration."
                ;;
            "vpc") 
                header="# VPC Terraform Module"
                description="Creates a VPC with public and private subnets across multiple availability zones, optimized for EKS clusters."
                ;;
            "kubernetes-addons") 
                header="# Kubernetes Addons Module"
                description="Installs and configures essential Kubernetes add-ons including cluster autoscaler, load balancer controller, and external DNS."
                ;;
            "acm-certificate") 
                header="# ACM Certificate Module"
                description="Creates and manages SSL/TLS certificates using AWS Certificate Manager with Route53 validation."
                ;;
            "route53") 
                header="# Route53 Module"
                description="Creates and manages Route53 hosted zones and DNS records for domain management."
                ;;
            *)
                header="# $(echo $dir_name | sed 's/-/ /g' | sed 's/\b\w/\U&/g') Module"
                description="Terraform module for managing $dir_name resources in AWS."
                ;;
        esac
    elif [[ "$dir_path" == *"bootstrap"* ]]; then
        # Bootstrap configuration
        header="# Bootstrap Configuration"
        description="Initial Terraform configuration for setting up foundational AWS resources and state management."
    elif [[ "$dir_path" == infrastructure/* ]]; then
        # Environment-specific configuration
        if [[ "$dir_path" == infrastructure/_envcommon ]]; then
            header="# Environment Common Configuration"
            description="Shared Terragrunt configuration and provider settings used across all environments."
        elif [[ "$dir_path" == infrastructure ]]; then
            header="# Infrastructure Root Configuration"
            description="Root-level Terragrunt configuration with shared backend and provider settings."
        else
            # Environment specific (dev/staging/etc.)
            local env_name="$parent_dir"
            if [[ "$dir_name" != "$env_name" ]]; then
                # This is a component within an environment
                header="# $dir_name - $env_name Environment"
                description="Terragrunt configuration for $dir_name in the $env_name environment.

## Configuration

This configuration uses the shared infrastructure module: \`infrastructure-modules/$dir_name\`

## Usage

\`\`\`bash
# Navigate to this directory
cd infrastructure/$env_name/$dir_name

# Plan the deployment
terragrunt plan

# Apply the deployment
terragrunt apply
\`\`\`"
            else
                # This is an environment directory itself
                header="# $env_name Environment Configuration"
                description="Environment-specific configuration and variables for the $env_name environment."
            fi
        fi
    else
        # Generic fallback
        header="# $(echo $dir_name | sed 's/-/ /g' | sed 's/\b\w/\U&/g')"
        description="Terraform configuration for $dir_name."
    fi
    
    # Generate terraform-docs content
    echo "   🤖 Generating terraform-docs content..."
    local tf_docs_content
    tf_docs_content=$(cd "$dir_path" && terraform-docs markdown . 2>/dev/null || echo "No terraform-docs content generated")
    
    # Create the README
    cat > "$readme_path" << EOF
$header

$description

<!-- BEGIN_TF_DOCS -->
$tf_docs_content
<!-- END_TF_DOCS -->
EOF
    
    echo "   ✅ Created $readme_path"
}

# Process all directories with .tf files
echo "🏗️  Processing all infrastructure directories..."

# Find all directories containing .tf files in the target paths
for base_dir in infrastructure-modules infrastructure bootstrap; do
    if [ -d "$base_dir" ]; then
        echo "📁 Processing $base_dir..."
        
        # Process base directory if it has .tf files
        create_terraform_readme "$base_dir"
        
        # Process all subdirectories recursively
        find "$base_dir" -type d | while read -r dir; do
            # Skip the base directory (already processed above)
            if [ "$dir" != "$base_dir" ]; then
                create_terraform_readme "$dir"
            fi
        done
    fi
done

echo ""
echo "🎉 README creation complete!"
echo ""
echo "📋 What was created:"
echo "   • READMEs for all directories with .tf files"
echo "   • Infrastructure modules with comprehensive terraform-docs"
echo "   • Environment-specific configurations with usage instructions"
echo "   • Bootstrap configuration documentation"
echo ""
echo "🔍 To see the results:"
echo "   find infrastructure infrastructure-modules bootstrap -name 'README.md'"
echo ""
echo "🚀 Next steps:"
echo "   1. Review the generated documentation"
echo "   2. Commit the changes: git add . && git commit -m 'Add comprehensive terraform-docs to all directories'"
echo "   3. Future changes will be auto-generated via pre-commit hooks"
