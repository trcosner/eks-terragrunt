#!/bin/bash

set -e

echo "🔧 Setting up pre-commit hooks for Terraform documentation..."

# Check if Homebrew is available (macOS)
if command -v brew &> /dev/null; then
    echo "📦 Installing tools via Homebrew..."
    
    # Install pre-commit
    if ! command -v pre-commit &> /dev/null; then
        brew install pre-commit
    fi
    
    # Install terraform-docs
    if ! command -v terraform-docs &> /dev/null; then
        brew install terraform-docs
    fi
    
    # Install tflint
    if ! command -v tflint &> /dev/null; then
        brew install tflint
    fi
    
else
    echo "⚠️  Homebrew not found. Please install the following tools manually:"
    echo "   - pre-commit: https://pre-commit.com/#installation"
    echo "   - terraform-docs: https://terraform-docs.io/user-guide/installation/"
    echo "   - tflint: https://github.com/terraform-linters/tflint#installation"
    exit 1
fi

# Install pre-commit hooks
echo "🪝 Installing pre-commit hooks..."
pre-commit install

# Run pre-commit on all files initially
echo "🔄 Running pre-commit on all files..."
pre-commit run --all-files || {
    echo "⚠️  Some pre-commit hooks failed. This is expected on first run."
    echo "   The hooks have auto-fixed formatting issues."
    echo "   Please review the changes and commit them."
}

echo "✅ Pre-commit setup complete!"
echo ""
echo "📋 What happens now:"
echo "   • terraform-docs will auto-update README.md files on each commit"
echo "   • Terraform code will be automatically formatted"
echo "   • Configuration will be validated before commits"
echo "   • Documentation will always stay in sync with code"
echo ""
echo "🚀 To manually run documentation generation:"
echo "   terraform-docs ."
