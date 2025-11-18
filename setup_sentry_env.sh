#!/bin/bash
# 为Sentry MCP设置SSL相关环境变量

echo "设置Sentry MCP SSL环境变量..."

# 如果Sentry MCP仍然遇到证书问题，可以使用以下环境变量：

# 1. 禁用Node.js SSL验证（不推荐，仅用于测试）
export NODE_TLS_REJECT_UNAUTHORIZED=0

# 2. 设置自定义CA证书路径
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_DIR=/etc/ssl/certs

# 3. 设置Node.js额外的CA证书
export NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/api.openai.com.crt

echo "环境变量已设置："
echo "NODE_TLS_REJECT_UNAUTHORIZED=${NODE_TLS_REJECT_UNAUTHORIZED}"
echo "SSL_CERT_FILE=${SSL_CERT_FILE}"
echo "NODE_EXTRA_CA_CERTS=${NODE_EXTRA_CA_CERTS}"
echo ""
echo "现在可以启动Sentry MCP了"