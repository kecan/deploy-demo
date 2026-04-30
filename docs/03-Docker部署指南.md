# Docker 部署指南

本指南介绍如何使用 Docker 容器化部署应用。

## 部署方式选择

| 方式 | 适用场景 | 本地需要 | 服务器需要 |
|-----|---------|---------|-----------|
| **方式一：CI/CD 自动部署** | 推荐，代码推送后自动部署 | Git | Docker |
| **方式二：本地构建部署** | 无法使用 GitHub Actions 时 | Git + Docker | Docker |

---

## 方式一：CI/CD 自动部署（推荐）

> 适合大多数场景，配置一次后，每次只需 `git push` 即可自动部署。

### 工作流程

```
本地电脑                    GitHub                        你的服务器
   │                          │                              │
   │  1. git push             │                              │
   ├─────────────────────────>│                              │
   │                          │  2. GitHub Actions 构建镜像   │
   │                          │  3. 推送镜像到 ghcr.io        │
   │                          │  4. SSH 连接服务器            │
   │                          ├─────────────────────────────>│
   │                          │  5. 拉取镜像并运行            │
   │                          │                              │
   │                          │              部署完成 ✅       │
```

### 第一步：服务器安装 Docker

SSH 连接到你的服务器（用 XShell），执行以下命令：

```bash
# 1. 一键安装 Docker
curl -fsSL https://get.docker.com | sh

# 2. 启动 Docker 并设置开机自启
sudo systemctl enable docker
sudo systemctl start docker

# 3. 验证安装成功
docker --version
```

如果显示版本号（如 `Docker version 24.x.x`），说明安装成功。

### 第二步：生成服务器 SSH 密钥

在服务器上执行：

```bash
# 1. 生成密钥对（一路回车，使用默认值）
ssh-keygen -t ed25519 -C "github-actions"

# 2. 将公钥添加到授权列表
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

# 3. 查看私钥内容（后面要复制到 GitHub）
cat ~/.ssh/id_ed25519
```

**重要**：记下私钥内容（从 `-----BEGIN` 到 `-----END` 的全部内容）。

### 第三步：配置 GitHub 仓库 Secrets

1. 打开你的 GitHub 仓库页面
2. 点击 `Settings` → `Secrets and variables` → `Actions`
3. 点击 `New repository secret`，依次添加以下 3 个：

| Name | Value |
|------|-------|
| `SERVER_HOST` | 你的服务器公网 IP，如 `47.116.32.226` |
| `SERVER_USER` | SSH 用户名，通常是 `root` |
| `SSH_PRIVATE_KEY` | 第二步获取的私钥内容（完整复制） |

### 第四步：开放服务器端口

在阿里云控制台开放端口：

**轻量应用服务器**：
1. 进入「轻量应用服务器」控制台
2. 选择你的服务器 → 「防火墙」
3. 添加规则：端口 `4000`，协议 `TCP`

**ECS 服务器**：
1. 进入「云服务器 ECS」控制台
2. 选择实例 → 「安全组」 → 「配置规则」
3. 添加入方向规则：端口 `4000`，授权对象 `0.0.0.0/0`

### 第五步：推送代码触发部署

在本地项目目录执行：

```bash
# 确保代码已提交
git add .
git commit -m "feat: 初次部署"

# 推送到 GitHub（触发自动部署）
git push origin main
```

### 第六步：查看部署进度

1. 打开 GitHub 仓库页面
2. 点击 `Actions` 标签
3. 查看最新的 workflow 运行状态
4. 点击进入可查看详细日志

部署成功后，访问 `http://你的服务器IP:4000` 即可看到应用。

### 后续更新部署

每次修改代码后，只需：

```bash
git add .
git commit -m "你的更新说明"
git push origin main
```

GitHub Actions 会自动完成构建和部署。

---

## 方式二：本地构建部署

> 适合无法使用 GitHub Actions 或需要离线部署的场景。

### 工作流程

```
本地电脑                                           你的服务器
   │                                                  │
   │  1. 本地构建 Docker 镜像                          │
   │  2. 导出镜像为文件                                │
   │  3. 上传镜像文件到服务器 ────────────────────────>│
   │                                                  │  4. 导入镜像
   │                                                  │  5. 运行容器
   │                                                  │
   │                                     部署完成 ✅    │
```

### 第一步：本地安装 Docker

**Windows / Mac**：

下载并安装 [Docker Desktop](https://www.docker.com/products/docker-desktop/)

安装完成后打开 Docker Desktop，等待启动完成。

**验证安装**：

打开终端（Windows 用 PowerShell，Mac 用 Terminal）：

```bash
docker --version
```

### 第二步：服务器安装 Docker

（同方式一的第一步，SSH 连接服务器执行）

```bash
curl -fsSL https://get.docker.com | sh
sudo systemctl enable docker
sudo systemctl start docker
docker --version
```

### 第三步：本地构建镜像

在本地项目目录执行：

```bash
# 进入项目目录
cd deploy-demo

# 构建镜像（注意最后有个点）
docker build -t deploy-demo:latest .

# 查看构建的镜像
docker images | grep deploy-demo
```

构建需要几分钟，完成后会显示镜像信息。

### 第四步：导出镜像文件

```bash
# 导出镜像为 tar 文件
docker save deploy-demo:latest -o deploy-demo-image.tar

# 查看文件大小
ls -lh deploy-demo-image.tar
```

### 第五步：上传镜像到服务器

**方式 A：使用 Xftp**

1. 打开 Xftp，连接服务器
2. 将 `deploy-demo-image.tar` 拖拽到服务器的 `/tmp` 目录

**方式 B：使用 scp 命令**

```bash
scp deploy-demo-image.tar root@你的服务器IP:/tmp/
```

### 第六步：服务器导入并运行

SSH 连接到服务器，执行：

```bash
# 1. 导入镜像
docker load -i /tmp/deploy-demo-image.tar

# 2. 查看镜像
docker images

# 3. 运行容器
docker run -d \
  --name deploy-demo-app \
  -p 4000:4000 \
  -v deploy-demo-data:/app/server/data \
  --restart unless-stopped \
  deploy-demo:latest

# 4. 查看运行状态
docker ps

# 5. 查看日志
docker logs -f deploy-demo-app
```

按 `Ctrl + C` 退出日志查看。

### 第七步：开放端口并访问

（同方式一的第四步，在阿里云控制台开放 4000 端口）

访问 `http://你的服务器IP:4000` 即可看到应用。

### 后续更新部署

每次更新需要重复以下步骤：

```bash
# 本地：重新构建并导出
docker build -t deploy-demo:latest .
docker save deploy-demo:latest -o deploy-demo-image.tar

# 上传到服务器（Xftp 或 scp）

# 服务器：停止旧容器，导入新镜像，运行
docker stop deploy-demo-app
docker rm deploy-demo-app
docker load -i /tmp/deploy-demo-image.tar
docker run -d \
  --name deploy-demo-app \
  -p 4000:4000 \
  -v deploy-demo-data:/app/server/data \
  --restart unless-stopped \
  deploy-demo:latest
```

---

## 验证部署

### 检查容器状态

```bash
# 查看运行中的容器
docker ps

# 应该看到类似输出：
# CONTAINER ID   IMAGE                 STATUS         PORTS
# abc123...      deploy-demo:latest    Up 2 minutes   0.0.0.0:4000->4000/tcp
```

### 检查应用日志

```bash
docker logs deploy-demo-app
```

应该看到：
```
🚀 Server running at http://localhost:4000
📁 Static files from: /app/client/dist
```

### 测试访问

```bash
# 服务器本地测试
curl http://localhost:4000

# 浏览器访问
http://你的服务器IP:4000
```

---

## 常用 Docker 命令

| 命令 | 说明 |
|------|------|
| `docker ps` | 查看运行中的容器 |
| `docker ps -a` | 查看所有容器（包括已停止） |
| `docker logs -f 容器名` | 查看容器日志（实时） |
| `docker stop 容器名` | 停止容器 |
| `docker start 容器名` | 启动已停止的容器 |
| `docker restart 容器名` | 重启容器 |
| `docker rm 容器名` | 删除容器（需先停止） |
| `docker images` | 查看本地镜像 |
| `docker rmi 镜像名` | 删除镜像 |
| `docker exec -it 容器名 sh` | 进入容器内部 |
| `docker system prune` | 清理无用的镜像和容器 |

---

## 多项目部署

同一台服务器部署多个项目，使用不同端口：

```
服务器
├── 项目A 容器 (端口 4000)
├── 项目B 容器 (端口 4001)
├── 项目C 容器 (端口 4002)
└── Nginx (端口 80/443) ← 统一代理，可选
```

### 运行第二个项目

```bash
docker run -d \
  --name project-b \
  -p 4001:4000 \
  -v project-b-data:/app/server/data \
  --restart unless-stopped \
  project-b:latest
```

记得在阿里云防火墙开放对应端口。

---

## 常见问题

### Q1: 构建镜像失败

**查看详细错误**：
```bash
docker build -t deploy-demo:latest . --progress=plain
```

**常见原因**：
- 网络问题：多试几次，或配置 Docker 镜像加速
- 内存不足：确保有足够的磁盘空间和内存

### Q2: 容器启动后立即退出

```bash
# 查看容器日志
docker logs deploy-demo-app

# 查看退出原因
docker inspect deploy-demo-app --format='{{.State.ExitCode}}'
```

### Q3: 端口被占用

```bash
# 查看端口占用
netstat -tlnp | grep 4000

# 停止占用端口的容器
docker stop <容器名或ID>
```

### Q4: 访问显示连接拒绝

检查清单：
1. 容器是否在运行：`docker ps`
2. 端口是否开放：阿里云防火墙/安全组
3. 应用是否正常：`docker logs deploy-demo-app`

### Q5: 如何更新部署

**CI/CD 方式**：直接 `git push`

**本地构建方式**：
```bash
# 服务器上执行
docker stop deploy-demo-app
docker rm deploy-demo-app
# 然后重新导入镜像并运行
```

### Q6: 如何回滚到旧版本

```bash
# 查看历史镜像
docker images

# 运行指定版本
docker stop deploy-demo-app
docker rm deploy-demo-app
docker run -d \
  --name deploy-demo-app \
  -p 4000:4000 \
  -v deploy-demo-data:/app/server/data \
  --restart unless-stopped \
  deploy-demo:旧版本标签
```

### Q7: 数据会丢失吗

不会。数据存储在 Docker 数据卷中（`deploy-demo-data`），重新部署时数据会保留。

查看数据卷：
```bash
docker volume ls
docker volume inspect deploy-demo-data
```
