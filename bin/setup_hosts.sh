#!/bin/bash
# Setup /etc/hosts for OpenAI API domain redirection
# This allows the proxy to intercept requests to api.openai.com

set -e

HOSTS_FILE="/etc/hosts"
HOSTS_ENTRY="127.0.0.1  api.openai.com"
BACKUP_FILE="${HOSTS_FILE}.backup.$(date +%Y%m%d-%H%M%S)"

echo "🌐 /etc/hosts Configuration Script"
echo "===================================="
echo ""
echo "This script will configure your system to redirect api.openai.com to localhost,"
echo "allowing the LiteLLM proxy to intercept OpenAI API requests."
echo ""

# Check if entry already exists
if grep -q "^127.0.0.1.*api\.openai\.com" "$HOSTS_FILE" 2>/dev/null; then
    echo "✅ /etc/hosts is already configured!"
    echo ""
    EXISTING_ENTRY=$(grep "api\.openai\.com" "$HOSTS_FILE")
    echo "   Current entry: $EXISTING_ENTRY"
    echo ""
    echo "No changes needed."
    exit 0
fi

# Check if we have root permissions
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script requires root/administrator privileges."
    echo ""
    echo "To configure /etc/hosts, run:"
    echo "   sudo bin/setup_hosts.sh"
    echo ""
    echo "Or manually add this line to $HOSTS_FILE:"
    echo "   $HOSTS_ENTRY"
    echo ""
    echo "⚠️  Without this configuration, MCP servers using api.openai.com won't use your proxy!"
    exit 2
fi

# Show what we're about to do
echo "📝 Will add the following entry to $HOSTS_FILE:"
echo "   $HOSTS_ENTRY"
echo ""
echo "📋 Backup will be created at: $BACKUP_FILE"
echo ""

# Interactive confirmation
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled by user"
    exit 1
fi

# Create backup
echo "💾 Creating backup..."
cp "$HOSTS_FILE" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# Add entry
echo ""
echo "✏️  Adding entry to $HOSTS_FILE..."
echo "" >> "$HOSTS_FILE"
echo "# LiteLLM OpenAI Proxy - Added by setup_hosts.sh on $(date)" >> "$HOSTS_FILE"
echo "$HOSTS_ENTRY" >> "$HOSTS_FILE"

echo "✅ Successfully added: $HOSTS_ENTRY"
echo ""

# Verify
echo "🔍 Verifying configuration..."
if grep -q "^127.0.0.1.*api\.openai\.com" "$HOSTS_FILE"; then
    echo "✅ Verification passed!"
    echo ""

    # Test DNS resolution
    echo "🧪 Testing DNS resolution..."
    if command -v ping &> /dev/null; then
        if ping -c 1 -W 1 api.openai.com 2>&1 | grep -q "127.0.0.1"; then
            echo "✅ api.openai.com now resolves to 127.0.0.1"
        else
            echo "⚠️  DNS resolution test inconclusive (this may be normal)"
        fi
    fi
else
    echo "❌ Verification failed! Entry not found in hosts file"
    exit 1
fi

echo ""
echo "🎉 Configuration complete!"
echo ""
echo "Next steps:"
echo "1. Start the LiteLLM proxy:"
echo "   sudo -E bin/start_litellm_proxy.sh"
echo "   # or"
echo "   make run API_KEY=xxx BASE_URL=xxx"
echo ""
echo "2. Test the configuration:"
echo "   curl -k https://api.openai.com:443/v1/models"
echo ""
echo "3. Configure your MCP server or application to use:"
echo "   OPENAI_BASE_URL=https://api.openai.com/v1"
echo "   # or"
echo "   OPENAI_BASE_URL=https://localhost:443/v1"
echo ""
echo "ℹ️  To remove this configuration later:"
echo "   sudo nano $HOSTS_FILE"
echo "   (Remove the line with api.openai.com)"
echo "   Or restore backup: sudo cp $BACKUP_FILE $HOSTS_FILE"
