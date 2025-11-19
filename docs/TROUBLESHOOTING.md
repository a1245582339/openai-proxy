# 🔧 Troubleshooting Guide

## ⚠️ MOST COMMON ISSUE: Missing /etc/hosts Configuration

**If your proxy works on one machine but not another**, the most likely cause is **missing /etc/hosts configuration**.

### Quick Fix

Run the automated setup script:
```bash
sudo bin/setup_hosts.sh
```

Or manually add this line to `/etc/hosts`:
```bash
# Add this line:
127.0.0.1  api.openai.com

# Command to add automatically:
echo "127.0.0.1  api.openai.com" | sudo tee -a /etc/hosts
```

**Why this is needed**:
- Many applications and MCP servers use `api.openai.com` as the endpoint
- Without this configuration, requests go to the real OpenAI servers, not your proxy
- This is often configured on one machine but forgotten when setting up another

**Verify it's working**:
```bash
# Check hosts file
cat /etc/hosts | grep openai

# Test DNS resolution
ping api.openai.com
# Should show 127.0.0.1

# Test proxy intercepts the request
curl -k https://api.openai.com:443/v1/models
# Should return response from your local proxy
```

---

## Proxy Running But Not Receiving Requests

**Symptom**:
- Proxy service starts successfully (Docker or shell script)
- No error messages in logs
- Client applications (like Sentry MCP) work but don't route through proxy
- No request logs appear in `docker logs -f litellm-proxy` or terminal output

**Root Cause**:
This usually happens when the client application is not properly configured to route requests through your proxy. The proxy is running, but network traffic isn't being directed to it.

---

## Diagnostic Steps

### Step 1: Verify Proxy is Actually Running

```bash
# Check if the service is listening on port 443
sudo netstat -tlnp | grep 443
# or
sudo lsof -i :443

# For Docker
docker ps | grep litellm-proxy
docker logs litellm-proxy --tail 50

# Expected output: Process listening on 0.0.0.0:443 or :::443
```

### Step 2: Test Direct Connection to Proxy

```bash
# Test 1: Check if proxy responds to health check
curl -k https://localhost:443/health
# Expected: {"status": "ok"} or similar

# Test 2: List models endpoint
curl -k https://localhost:443/v1/models
# Expected: JSON response with model list

# Test 3: Make a test chat completion request
curl -k https://localhost:443/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-key" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 50
  }'
# Expected: JSON response with Claude's reply
# If this works, the proxy itself is fine - it's a client configuration issue
```

### Step 3: Check Client Configuration

The most common issue is that **your client application (Sentry MCP, etc.) is still using the original OpenAI endpoint**, not your local proxy.

**For Sentry MCP or other MCP servers**, check the configuration:

```bash
# Find your MCP configuration file
# Usually located at:
# - macOS: ~/Library/Application Support/Claude/claude_desktop_config.json
# - Linux: ~/.config/Claude/claude_desktop_config.json
# - Windows: %APPDATA%/Claude/claude_desktop_config.json

# Check the OpenAI configuration in the MCP server settings
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

**Verify the MCP server has these settings**:

```json
{
  "mcpServers": {
    "your-mcp-server": {
      "env": {
        "OPENAI_API_KEY": "dummy-key",
        "OPENAI_BASE_URL": "https://localhost:443/v1"
      }
    }
  }
}
```

**Critical points**:
- `OPENAI_BASE_URL` must point to your proxy (`https://localhost:443/v1`)
- If using hostname instead of localhost, ensure DNS resolves correctly
- Port must match your proxy's listening port (443 by default)

### Step 4: Check SSL Certificate Issues

Your proxy uses self-signed certificates, which clients may reject:

```bash
# Check certificate validity
openssl s_client -connect localhost:443 -showcerts

# If using custom hostname (e.g., api.openai.com)
openssl s_client -connect api.openai.com:443 -showcerts
```

**Common SSL solutions**:

#### Option A: Disable SSL verification in client (development only)

For Node.js-based MCP servers:
```json
{
  "mcpServers": {
    "your-mcp-server": {
      "env": {
        "OPENAI_API_KEY": "dummy-key",
        "OPENAI_BASE_URL": "https://localhost:443/v1",
        "NODE_TLS_REJECT_UNAUTHORIZED": "0"
      }
    }
  }
}
```

For Python clients, set environment variable:
```bash
export PYTHONHTTPSVERIFY=0
# or
export CURL_CA_BUNDLE=""
```

#### Option B: Trust the self-signed certificate (recommended)

**macOS:**
```bash
# Trust the certificate
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain cert.pem
```

**Linux:**
```bash
# Add to system trust store
sudo cp cert.pem /usr/local/share/ca-certificates/litellm-proxy.crt
sudo update-ca-certificates
```

**Windows:**
```powershell
# Use certmgr.msc to import cert.pem to "Trusted Root Certification Authorities"
# Or via PowerShell:
Import-Certificate -FilePath "cert.pem" -CertStoreLocation Cert:\LocalMachine\Root
```

### Step 5: Check Network Routing (if using /etc/hosts)

If you configured `/etc/hosts` to redirect `api.openai.com` to localhost:

```bash
# Check hosts file
cat /etc/hosts | grep openai

# Expected line:
# 127.0.0.1  api.openai.com

# Test DNS resolution
ping api.openai.com
# Should resolve to 127.0.0.1

# Test if traffic is routed
curl -k https://api.openai.com:443/v1/models
# Should hit your local proxy, not OpenAI
```

**If hosts file was configured on old machine but not new one**:
```bash
# Linux/macOS - Add this line to /etc/hosts (requires sudo)
echo "127.0.0.1  api.openai.com" | sudo tee -a /etc/hosts

# Windows - Edit C:\Windows\System32\drivers\etc\hosts as Administrator
# Add line: 127.0.0.1  api.openai.com
```

### Step 6: Monitor Proxy Logs in Real-Time

While testing, watch logs to see if requests arrive:

```bash
# Docker method
docker logs -f litellm-proxy

# Shell script method
# Check terminal where script is running

# You should see lines like:
# POST /v1/chat/completions
# 200 OK
```

**If you see NO logs when making requests**, the traffic is not reaching your proxy.

---

## Common Solution Checklist

Try these in order:

1. ✅ **Verify proxy is running**: `docker ps` or `ps aux | grep litellm`
2. ✅ **Test direct access**: `curl -k https://localhost:443/v1/models`
3. ✅ **Check client config**: Ensure `OPENAI_BASE_URL=https://localhost:443/v1`
4. ✅ **Disable SSL verification**: Set `NODE_TLS_REJECT_UNAUTHORIZED=0` (Node.js) or `PYTHONHTTPSVERIFY=0` (Python)
5. ✅ **Check hosts file**: `cat /etc/hosts | grep openai` (if using domain redirection)
6. ✅ **Restart client application**: Restart MCP server or application after config changes
7. ✅ **Check firewall**: Ensure localhost:443 is not blocked
8. ✅ **Try different port**: If 443 is problematic, use 8443 instead

---

## Quick Fix for MCP Servers

If you're using this proxy with Sentry MCP or similar:

### 1. Update MCP Configuration

Edit `claude_desktop_config.json`:

**macOS:**
```bash
nano ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

**Linux:**
```bash
nano ~/.config/Claude/claude_desktop_config.json
```

**Windows:**
```powershell
notepad %APPDATA%\Claude\claude_desktop_config.json
```

**Configuration:**
```json
{
  "mcpServers": {
    "sentry": {
      "command": "npx",
      "args": ["-y", "@cloudflare/mcp-server-sentry"],
      "env": {
        "SENTRY_AUTH_TOKEN": "your-token",
        "SENTRY_ORG_SLUG": "your-org",
        "OPENAI_API_KEY": "dummy-key",
        "OPENAI_BASE_URL": "https://localhost:443/v1",
        "NODE_TLS_REJECT_UNAUTHORIZED": "0"
      }
    }
  }
}
```

### 2. Restart Claude Desktop

Completely quit and restart Claude Desktop application (not just refresh).

**macOS:**
```bash
# Quit Claude Desktop completely
# Then reopen from Applications

# Or via command line:
killall Claude && open -a Claude
```

**Windows:**
```powershell
# Close Claude Desktop from system tray
# Or via Task Manager, then restart
```

**Linux:**
```bash
# Kill and restart
pkill claude && claude
```

### 3. Verify in Logs

```bash
docker logs -f litellm-proxy
# Now you should see requests when using Sentry MCP features
```

---

## Specific Issue: Different Machine Behavior

**Symptom**: Proxy works on one machine but not on another

**⚠️ MOST LIKELY CAUSE**: Missing /etc/hosts configuration (see section at top of this document)

**Common causes (in order of likelihood)**:

1. **Missing /etc/hosts entry** ⭐ **MOST COMMON**

   This is the #1 reason proxies work on one machine but not another!

   ```bash
   # Quick fix - run setup script:
   sudo bin/setup_hosts.sh

   # Or manually check on new machine:
   cat /etc/hosts | grep openai

   # If missing, add:
   echo "127.0.0.1  api.openai.com" | sudo tee -a /etc/hosts

   # Verify it worked:
   ping api.openai.com  # Should show 127.0.0.1
   curl -k https://api.openai.com:443/v1/models  # Should hit your proxy
   ```

   **Why this happens**:
   - You configured `/etc/hosts` on your original machine
   - You forgot to do it on the new machine
   - Applications using `api.openai.com` endpoint go to real OpenAI instead of your proxy

2. **Firewall differences**: New machine may have stricter firewall rules
   ```bash
   # Linux - Check firewall
   sudo ufw status
   sudo ufw allow 443/tcp

   # macOS - Check firewall
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
   ```

3. **Different port bindings**: Port 443 may be occupied
   ```bash
   # Check what's using port 443
   sudo lsof -i :443

   # If occupied, use different port (e.g., 8443)
   # Edit start script or Docker run command to use PORT=8443
   # Then update client config: OPENAI_BASE_URL=https://localhost:8443/v1
   ```

4. **Certificate not generated**: Certificates may not exist on new machine
   ```bash
   # Check if certificates exist
   ls -la cert.pem key.pem

   # If missing, they'll be auto-generated on first run
   # Or manually generate:
   openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes \
     -subj "/C=US/ST=CA/L=SF/O=LiteLLM/CN=api.openai.com"
   ```

5. **Client config not transferred**: MCP config may differ between machines
   ```bash
   # Compare configs between machines
   # Old machine:
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json

   # Ensure OPENAI_BASE_URL is set on new machine
   ```

6. **Docker network issues**: Docker may use different network on new machine
   ```bash
   # Check Docker networking
   docker network ls
   docker inspect litellm-proxy | grep IPAddress

   # Try using host network mode
   docker run -d --network host \
     -e ANTHROPIC_API_KEY=xxx \
     -e ANTHROPIC_BASE_URL=xxx \
     litellm-openai-proxy
   ```

---

## Debug Mode

Enable debug mode to see detailed logs:

**Docker:**
```bash
make run API_KEY=xxx BASE_URL=xxx MODEL=claude-sonnet-4-5 DEBUG=true

# Or directly:
docker run -d \
  --name litellm-proxy \
  -p 443:443 \
  -e ANTHROPIC_API_KEY=xxx \
  -e ANTHROPIC_BASE_URL=xxx \
  -e DEBUG=true \
  litellm-openai-proxy
```

**Shell script:**
```bash
ANTHROPIC_API_KEY=xxx \
ANTHROPIC_BASE_URL=xxx \
DEBUG=true \
sudo -E bin/start_litellm_proxy.sh
```

Debug mode will show:
- Incoming request details
- Model routing decisions
- Full API request/response bodies
- SSL handshake information

---

## Still Having Issues?

If none of the above solutions work:

1. **Capture detailed diagnostics:**
   ```bash
   # Save to file for analysis
   {
     echo "=== Proxy Status ==="
     docker ps | grep litellm || ps aux | grep litellm

     echo -e "\n=== Port Check ==="
     sudo lsof -i :443

     echo -e "\n=== Hosts File ==="
     cat /etc/hosts | grep openai

     echo -e "\n=== Direct Test ==="
     curl -k -v https://localhost:443/v1/models

     echo -e "\n=== Proxy Logs ==="
     docker logs litellm-proxy --tail 100 2>&1
   } > diagnostic.txt
   ```

2. **Test with simplified setup:**
   ```bash
   # Use a simple Python script to test
   cat > test_proxy.py << 'EOF'
import openai
import os

os.environ['OPENAI_API_KEY'] = 'dummy-key'
os.environ['OPENAI_BASE_URL'] = 'https://localhost:443/v1'

# Disable SSL verification for testing
import urllib3
urllib3.disable_warnings()

client = openai.OpenAI(
    api_key='dummy-key',
    base_url='https://localhost:443/v1',
    http_client=openai.DefaultHttpxClient(verify=False)
)

response = client.chat.completions.create(
    model='gpt-4',
    messages=[{'role': 'user', 'content': 'Hello'}]
)
print(response.choices[0].message.content)
EOF

   python3 test_proxy.py
   ```

3. **Check for conflicting services:**
   ```bash
   # See if another proxy or service is interfering
   sudo lsof -i :443
   ps aux | grep -E 'proxy|litellm|openai'
   ```

If you're still stuck, create an issue with:
- Your diagnostic.txt output
- OS version and type (Linux/macOS/Windows)
- Startup method (Docker/shell script)
- Client application type (MCP server, Python script, etc.)
