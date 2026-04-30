# Deploy Demo - 部署实践项目

一个用于学习服务器部署的全栈 Todo 应用，包含三种部署方式的完整配置和文档。

## 技术栈

- **前端**: Vue 3 + Vite
- **后端**: Node.js + Express
- **数据库**: SQLite (better-sqlite3)
- **进程管理**: PM2
- **容器化**: Docker

## 项目结构

```
deploy-demo/
├── client/                 # 前端代码
│   ├── src/
│   │   ├── App.vue
│   │   ├── main.js
│   │   └── style.css
│   ├── index.html
│   ├── vite.config.js
│   └── package.json
├── server/                 # 后端代码
│   ├── src/
│   │   └── index.js
│   ├── data/              # SQLite 数据库目录
│   └── package.json
├── docs/                   # 部署文档
│   ├── 01-手动部署指南.md
│   ├── 02-GitHub-CICD部署指南.md
│   └── 03-Docker部署指南.md
├── scripts/                # 部署脚本
│   ├── deploy-manual.sh
│   └── server-init.sh
├── nginx/                  # Nginx 配置
│   └── deploy-demo.conf
├── .github/workflows/      # GitHub Actions
│   ├── deploy.yml
│   └── docker-deploy.yml
├── Dockerfile
├── docker-compose.yml
├── ecosystem.config.cjs    # PM2 配置
└── package.json
```

## 快速开始

### 1. 安装依赖

```bash
npm run install:all
```

### 2. 本地开发

```bash
npm run dev
```

前端访问: http://localhost:3000
后端 API: http://localhost:4000

### 3. 构建

```bash
npm run build
```

## 部署方式

本项目支持三种部署方式，请根据需求选择：

| 方式 | 适用场景 | 文档 |
|------|---------|------|
| 手动部署 | 学习基础、小型项目 | [01-手动部署指南](./docs/01-手动部署指南.md) |
| CI/CD 部署 | 团队协作、自动化需求 | [02-GitHub-CICD部署指南](./docs/02-GitHub-CICD部署指南.md) |
| Docker 部署 | 环境隔离、微服务架构 | [03-Docker部署指南](./docs/03-Docker部署指南.md) |

## API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/todos | 获取所有 Todo |
| POST | /api/todos | 创建 Todo |
| PUT | /api/todos/:id | 更新 Todo |
| DELETE | /api/todos/:id | 删除 Todo |
| GET | /api/health | 健康检查 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| PORT | 4000 | 服务器端口 |
| NODE_ENV | development | 运行环境 |
| DB_PATH | ./data/todos.db | 数据库路径 |

## 常用命令

```bash
# 开发
npm run dev           # 同时启动前后端
npm run dev:client    # 只启动前端
npm run dev:server    # 只启动后端

# 构建
npm run build         # 构建前端

# 生产
npm start             # 启动生产服务

# Docker
docker compose up -d  # 启动容器
docker compose down   # 停止容器
```

## License

MIT
