#!/bin/bash

# GitHub Self-Hosted Runner Setup Script
# This script sets up a GitHub Actions runner on your local machine

echo "🚀 Setting up GitHub Actions Self-Hosted Runner"
echo "================================================"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS. Please adapt for your OS."
    exit 1
fi

# Create runner directory
RUNNER_DIR="$HOME/github-runner"
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

echo "📁 Created runner directory: $RUNNER_DIR"

# Download the latest runner package for macOS
echo "⬇️  Downloading GitHub Actions runner..."
curl -o actions-runner-osx-x64-2.319.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.319.1/actions-runner-osx-x64-2.319.1.tar.gz

# Extract the installer
echo "📦 Extracting runner package..."
tar xzf ./actions-runner-osx-x64-2.319.1.tar.gz

echo ""
echo "✅ Runner downloaded and extracted!"
echo ""
echo "🔧 Next Steps:"
echo "1. Go to your GitHub repository: https://github.com/sfc-gh-susmani/mammoth-dynamic-tables"
echo "2. Navigate to: Settings → Actions → Runners → New self-hosted runner"
echo "3. Select macOS as the operating system"
echo "4. Copy the configuration command that looks like:"
echo "   ./config.sh --url https://github.com/sfc-gh-susmani/mammoth-dynamic-tables --token XXXXX"
echo "5. Run that command in this directory: $RUNNER_DIR"
echo "6. When prompted for runner name, use: 'local-snowflake-runner'"
echo "7. For labels, add: 'self-hosted,macOS,snowflake-enabled'"
echo "8. Start the runner with: ./run.sh"
echo ""
echo "💡 The runner will use your local network connection (VPN-enabled)"
echo "💡 This allows deployment to Snowflake through your corporate network"
echo ""
echo "📝 Current directory: $(pwd)"
