#!/bin/bash
# 服务器初始化脚本 - 在服务器上执行
# 用于首次部署前准备服务器环境

set -e

echo "=========================================="
echo "  服务器环境初始化脚本"
echo "=========================================="

# 更新系统
echo "[1/6] 更新系统包..."
apt update && apt upgrade -y

# 安装 Node.js
echo "[2/6] 安装 Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "Node.js 版本: $(node --version)"
echo "NPM 版本: $(npm --version)"

# 安装 PM2
echo "[3/6] 安装 PM2..."
npm install -g pm2
pm2 startup

# 安装 Nginx
echo "[4/6] 安装 Nginx..."
apt install -y nginx

# 安装 Docker (可选)
echo "[5/6] 安装 Docker..."
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER

# 配置防火墙
echo "[6/6] 配置防火墙..."
ufw allow ssh
ufw allow 80
ufw allow 443
ufw allow 4000
ufw --force enable

echo ""
echo "=========================================="
echo "  ✅ 服务器初始化完成!"
echo "=========================================="
echo ""
echo "已安装:"
echo "  - Node.js $(node --version)"
echo "  - NPM $(npm --version)"
echo "  - PM2 $(pm2 --version)"
echo "  - Nginx $(nginx -v 2>&1 | cut -d'/' -f2)"
echo "  - Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
echo ""
echo "防火墙已开放: 22, 80, 443, 4000 端口"
echo ""
echo "下一步:"
echo "  1. 配置 SSH 密钥登录 (推荐)"
echo "  2. 执行部署脚本"
