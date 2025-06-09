#!/bin/bash

# AI-powered documentation generator using GitHub Copilot CLI
# This script uses GitHub Copilot to generate intelligent documentation

set -e

echo "🤖 Generating AI-powered documentation with GitHub Copilot..."

# Function to generate docs for a Terraform module
generate_module_docs() {
    local module_path="$1"
    local readme_path="$module_path/README.md"
    
    echo "📝 Processing module: $module_path"
    
    # Get all Terraform files in the module
    local tf_files=$(find "$module_path" -name "*.tf" -type f | head -10)
    
    if [ -z "$tf_files" ]; then
        echo "⚠️  No Terraform files found in $module_path"
        return
    fi
    
    # Create a prompt for GitHub Copilot
    local prompt="Based on the following Terraform code, generate comprehensive documentation including:
1. Module overview and purpose
2. Architecture explanation
3. Usage examples
4. Prerequisites
5. Security considerations
6. Best practices

Terraform files content:"
    
    # Add content of each Terraform file to the prompt
    for tf_file in $tf_files; do
        if [ -f "$tf_file" ]; then
            prompt="$prompt

File: $(basename "$tf_file")
\`\`\`hcl
$(cat "$tf_file")
\`\`\`"
        fi
    done
    
    # Use GitHub Copilot CLI to generate documentation
    if command -v gh &> /dev/null && gh copilot --version &> /dev/null; then
        echo "🤖 Using GitHub Copilot to generate documentation..."
        
        # Create temporary file with prompt
        local temp_prompt=$(mktemp)
        echo "$prompt" > "$temp_prompt"
        
        # Generate documentation using Copilot
        local ai_docs=$(gh copilot suggest -t shell "Generate markdown documentation for Terraform module based on: $(cat "$temp_prompt")" | tail -n +3)
        
        # Create or update README.md
        if [ ! -f "$readme_path" ]; then
            echo "# $(basename "$module_path") Module" > "$readme_path"
            echo "" >> "$readme_path"
        fi
        
        # Add AI-generated content
        echo "<!-- BEGIN_AI_DOCS -->" >> "$readme_path"
        echo "$ai_docs" >> "$readme_path"
        echo "<!-- END_AI_DOCS -->" >> "$readme_path"
        
        # Clean up
        rm "$temp_prompt"
        
        echo "✅ Generated AI documentation for $module_path"
    else
        echo "⚠️  GitHub Copilot CLI not available. Install with: gh extension install github/gh-copilot"
    fi
}

# Process all infrastructure modules
if [ -d "infrastructure-modules" ]; then
    for module in infrastructure-modules/*/; do
        if [ -d "$module" ]; then
            generate_module_docs "$module"
        fi
    done
fi

# Process environment-specific modules
if [ -d "infrastructure" ]; then
    for env in infrastructure/dev infrastructure/staging infrastructure/prod; do
        if [ -d "$env" ]; then
            for module in "$env"/*/; do
                if [ -d "$module" ]; then
                    generate_module_docs "$module"
                fi
            done
        fi
    done
fi

echo "🎉 AI documentation generation complete!"
