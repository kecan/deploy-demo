# GitHub CI/CD 部署指南

本指南介绍如何通过 GitHub Actions 实现代码提交后自动构建和部署。

## 目录

1. [工作流程概述](#工作流程概述)
2. [前置准备](#前置准备)
3. [配置 GitHub Secrets](#配置-github-secrets)
4. [部署流程详解](#部署流程详解)
5. [触发部署](#触发部署)
6. [监控与调试](#监控与调试)
7. [常见问题](#常见问题)

---

## 工作流程概述

```
┌─────────────────────────────────────────────────────────────────┐
│                        CI/CD 工作流程                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [本地开发] ──> [Git Push] ──> [GitHub Actions]                  │
│                                      │                          │
│                              ┌───────┴───────┐                  │
│                              │               │                  │
│                         [Build Job]    [Deploy Job]             │
│                              │               │                  │
│                      ┌───────┴───────┐       │                  │
│                      │               │       │                  │
│               [Install Deps]  [Build Client] │                  │
│                      │               │       │                  │
│                      └───────┬───────┘       │                  │
│                              │               │                  │
│                      [Create Package]        │                  │
│                              │               │                  │
│                      [Upload Artifact] ──────┤                  │
│                                              │                  │
│                                      [Download Artifact]        │
│                                              │                  │
│                                      [SSH Deploy]               │
│                                              │                  │
│                                      [Health Check]             │
│                                              │                  │
│                                        [完成 ✅]                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 前置准备

### 1. GitHub 仓库

确保项目已推送到 GitHub 仓库。

```bash
# 初始化 Git（如果还没有）
git init
git add .
git commit -m "Initial commit"

# 添加远程仓库
git remote add origin https://github.com/your-username/deploy-demo.git
git branch -M main
git push -u origin main
```

### 2. 服务器准备

服务器需要完成以下配置（参考手动部署指南）：

- [x] Node.js 20.x 已安装
- [x] PM2 已安装并配置开机启动
- [x] Nginx 已安装（可选）
- [x] 防火墙端口已开放

### 3. SSH 密钥配置

GitHub Actions 需要通过 SSH 连接到服务器。

#### 在服务器上生成专用密钥

```bash
# 在服务器上执行
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github-actions -N ""

# 添加公钥到授权文件
cat ~/.ssh/github-actions.pub >> ~/.ssh/authorized_keys

# 显示私钥（稍后需要复制到 GitHub）
cat ~/.ssh/github-actions
```

> ⚠️ **安全提示**：建议为 CI/CD 创建专用的部署密钥，而非使用个人 SSH 密钥。

---

## 配置 GitHub Secrets

在 GitHub 仓库中配置以下 Secrets：

### 1. 进入 Secrets 设置页面

`仓库页面` → `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

### 2. 添加以下 Secrets

| Secret 名称 | 值说明 | 示例 |
|-------------|--------|------|
| `SERVER_HOST` | 服务器公网 IP | `47.96.123.456` |
| `SERVER_USER` | SSH 登录用户名 | `root` 或 `deploy` |
| `SSH_PRIVATE_KEY` | SSH 私钥内容 | 上一步生成的私钥完整内容 |

### 3. 添加私钥

1. 点击 `New repository secret`
2. Name: `SSH_PRIVATE_KEY`
3. Secret: 粘贴完整的私钥内容（包括 BEGIN 和 END 行）

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAA...
...
-----END OPENSSH PRIVATE KEY-----
```

---

## 部署流程详解

项目配置了两个工作流，选择其一使用：

### 工作流 1: 标准部署 (deploy.yml)

适用于直接在服务器上运行 Node.js 应用。

```yaml
# .github/workflows/deploy.yml 关键步骤

jobs:
  build:
    # 1. 检出代码
    # 2. 安装 Node.js
    # 3. 安装依赖并构建前端
    # 4. 创建部署包并上传为 Artifact

  deploy:
    # 5. 下载 Artifact
    # 6. 通过 SSH 上传到服务器
    # 7. 在服务器上解压、安装依赖、重启应用
    # 8. 健康检查
```

### 工作流 2: Docker 部署 (docker-deploy.yml)

适用于使用 Docker 容器化部署。详见 [Docker 部署指南](./03-Docker部署指南.md)。

---

## 触发部署

### 自动触发

推送到 `main` 分支时自动触发：

```bash
git add .
git commit -m "feat: add new feature"
git push origin main
```

### 手动触发

1. 进入 `Actions` 页面
2. 选择 `Build and Deploy` 工作流
3. 点击 `Run workflow`
4. 选择分支，点击 `Run workflow`

---

## 监控与调试

### 查看工作流运行状态

1. 进入仓库的 `Actions` 页面
2. 点击具体的工作流运行记录
3. 展开各个步骤查看详细日志

### 常见日志位置

- **Build 阶段问题**：查看 "Install dependencies" 或 "Build client" 步骤
- **部署阶段问题**：查看 "Deploy to server" 步骤
- **健康检查失败**：查看 "Health check" 步骤

### 在服务器上调试

```bash
# 查看 PM2 状态
pm2 status

# 查看应用日志
pm2 logs deploy-demo

# 查看 Nginx 日志
sudo tail -f /var/log/nginx/error.log

# 手动测试 API
curl http://localhost:4000/api/health
```

---

## 工作流配置说明

### deploy.yml 完整解读

```yaml
name: Build and Deploy

# 触发条件
on:
  push:
    branches: [main]      # main 分支推送时触发
  workflow_dispatch:      # 允许手动触发

# 环境变量
env:
  SERVER_HOST: ${{ secrets.SERVER_HOST }}
  SERVER_USER: ${{ secrets.SERVER_USER }}
  DEPLOY_PATH: /home/${{ secrets.SERVER_USER }}/deploy-demo

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      # 检出代码
      - uses: actions/checkout@v4

      # 设置 Node.js，启用缓存加速
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      # 构建前端
      - run: npm ci && npm run build
        working-directory: ./client

      # 创建部署包
      - run: |
          mkdir -p deploy-package
          cp -r client/dist deploy-package/client-dist
          cp -r server deploy-package/server
          tar -czf deploy-package.tar.gz deploy-package

      # 上传为 Artifact
      - uses: actions/upload-artifact@v4
        with:
          name: deploy-package
          path: deploy-package.tar.gz

  deploy:
    needs: build           # 依赖 build 完成
    runs-on: ubuntu-latest
    steps:
      # 下载 Artifact
      - uses: actions/download-artifact@v4

      # 配置 SSH
      - run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.SERVER_HOST }} >> ~/.ssh/known_hosts

      # 上传并部署
      - run: |
          scp deploy-package.tar.gz $SERVER_USER@$SERVER_HOST:/tmp/
          ssh $SERVER_USER@$SERVER_HOST << 'ENDSSH'
            # 部署脚本...
          ENDSSH

      # 健康检查
      - run: curl -f http://$SERVER_HOST:4000/api/health
```

---

## 高级配置

### 添加构建缓存

已在配置中启用 npm 缓存，首次构建后会更快。

### 添加通知

可以在工作流末尾添加通知步骤：

```yaml
- name: Notify on success
  if: success()
  run: |
    curl -X POST "https://your-webhook-url" \
      -H "Content-Type: application/json" \
      -d '{"text": "✅ 部署成功!"}'

- name: Notify on failure
  if: failure()
  run: |
    curl -X POST "https://your-webhook-url" \
      -H "Content-Type: application/json" \
      -d '{"text": "❌ 部署失败!"}'
```

### 多环境部署

可以配置不同环境（staging/production）：

```yaml
jobs:
  deploy-staging:
    if: github.ref == 'refs/heads/develop'
    # 部署到测试环境...

  deploy-production:
    if: github.ref == 'refs/heads/main'
    # 部署到生产环境...
```

---

## 常见问题

### Q1: SSH 连接失败

**错误信息**: `Permission denied (publickey)`

**解决方案**:
1. 确认 `SSH_PRIVATE_KEY` 包含完整私钥（包括 BEGIN/END 行）
2. 确认服务器上 `~/.ssh/authorized_keys` 包含对应公钥
3. 检查服务器 SSH 配置：
   ```bash
   sudo cat /etc/ssh/sshd_config | grep PubkeyAuthentication
   # 应该是 PubkeyAuthentication yes
   ```

### Q2: Build 失败

**常见原因**:
- `package-lock.json` 未提交到仓库
- Node.js 版本不匹配

**解决方案**:
```bash
# 本地重新生成 lock 文件
rm -rf node_modules client/node_modules server/node_modules
npm install
cd client && npm install && cd ..
cd server && npm install && cd ..
git add .
git commit -m "chore: update lock files"
git push
```

### Q3: 健康检查失败

**排查步骤**:
1. SSH 到服务器检查应用状态
2. 查看 PM2 日志是否有错误
3. 确认端口 4000 可访问

```bash
# 在服务器上
pm2 logs deploy-demo
curl http://localhost:4000/api/health
```

### Q4: 部署成功但网站无法访问

**检查项**:
1. 阿里云安全组是否开放 4000 端口
2. 服务器防火墙是否开放 4000 端口
3. Nginx 配置是否正确（如果使用）

```bash
# 检查防火墙
sudo ufw status

# 检查端口监听
netstat -tlnp | grep 4000
```

### Q5: 如何回滚

部署脚本会自动创建备份，手动回滚：

```bash
# SSH 到服务器
cd ~/deploy-demo

# 查看备份
ls -la backup-*

# 回滚到指定备份
rm -rf server client-dist
cp -r backup-20240301-120000/server ./
cp -r backup-20240301-120000/client-dist ./

# 重启
pm2 restart deploy-demo
```

---

## 最佳实践

1. **保护 main 分支**：在 GitHub 设置中启用分支保护规则
2. **Code Review**：使用 Pull Request 进行代码审查
3. **环境隔离**：使用不同分支部署到不同环境
4. **监控告警**：配置部署通知（Slack、钉钉等）
5. **定期备份**：数据库数据定期备份到云存储
