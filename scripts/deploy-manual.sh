#!/bin/bash
# 手动部署脚本 - 在本地执行
# 用法: ./scripts/deploy-manual.sh <服务器用户名> <服务器IP>

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 参数检查
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "用法: $0 <服务器用户名> <服务器IP>"
    echo "示例: $0 root 123.45.67.89"
    exit 1
fi

SERVER_USER=$1
SERVER_HOST=$2
DEPLOY_PATH="/home/${SERVER_USER}/deploy-demo"
PACKAGE_NAME="deploy-package-$(date +%Y%m%d-%H%M%S).tar.gz"

log_info "开始部署流程..."

# 1. 构建前端
log_info "构建前端..."
cd client
npm ci
npm run build
cd ..

# 2. 打包
log_info "创建部署包..."
mkdir -p deploy-package/client
cp -r client/dist deploy-package/client/
cp -r server deploy-package/server
cp ecosystem.config.cjs deploy-package/
rm -rf deploy-package/server/node_modules
rm -rf deploy-package/server/data
tar -czf $PACKAGE_NAME deploy-package
rm -rf deploy-package

log_info "部署包大小: $(du -h $PACKAGE_NAME | cut -f1)"

# 3. 上传
log_info "上传到服务器..."
scp $PACKAGE_NAME ${SERVER_USER}@${SERVER_HOST}:/tmp/

# 4. 远程部署
log_info "执行远程部署..."
ssh ${SERVER_USER}@${SERVER_HOST} << ENDSSH
    set -e

    echo "创建部署目录..."
    mkdir -p ${DEPLOY_PATH}
    cd ${DEPLOY_PATH}

    # 备份
    if [ -d "server" ]; then
        BACKUP_DIR="backup-\$(date +%Y%m%d-%H%M%S)"
        echo "备份旧版本到 \$BACKUP_DIR..."
        mkdir -p \$BACKUP_DIR
        cp -r server \$BACKUP_DIR/ 2>/dev/null || true
        cp -r client \$BACKUP_DIR/ 2>/dev/null || true
    fi

    # 解压
    echo "解压新版本..."
    tar -xzf /tmp/${PACKAGE_NAME} -C /tmp/
    rm -rf client server
    mv /tmp/deploy-package/client ./
    mv /tmp/deploy-package/server ./
    cp /tmp/deploy-package/ecosystem.config.cjs ./

    # 安装依赖
    echo "安装依赖..."
    cd server
    npm ci --only=production
    mkdir -p data

    # 重启应用
    echo "重启应用..."
    cd ..
    mkdir -p logs
    pm2 reload ecosystem.config.cjs --env production || pm2 start ecosystem.config.cjs --env production
    pm2 save

    # 清理
    rm -f /tmp/${PACKAGE_NAME}
    rm -rf /tmp/deploy-package

    # 只保留最近3个备份
    ls -dt backup-* 2>/dev/null | tail -n +4 | xargs rm -rf 2>/dev/null || true

    echo "✅ 部署完成!"
    pm2 status
ENDSSH

# 5. 健康检查
log_info "执行健康检查..."
sleep 3
if curl -s -f "http://${SERVER_HOST}:4000/api/health" > /dev/null; then
    log_info "✅ 健康检查通过!"
else
    log_error "健康检查失败!"
    exit 1
fi

# 6. 清理本地
rm -f $PACKAGE_NAME

log_info "🎉 部署成功完成!"
echo ""
echo "访问地址: http://${SERVER_HOST}:4000"
