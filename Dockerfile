# 阶段1: 构建前端
FROM node:20-alpine AS frontend-builder

WORKDIR /app/client
COPY client/package*.json ./
RUN npm ci
COPY client/ ./
RUN npm run build

# 阶段2: 生产镜像
FROM node:20-alpine AS production

WORKDIR /app

# 复制后端
COPY server/package*.json ./server/
WORKDIR /app/server
RUN npm ci --only=production

COPY server/ ./

# 复制前端构建产物
COPY --from=frontend-builder /app/client/dist ../client/dist

# 创建数据目录
RUN mkdir -p /app/server/data

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=4000

EXPOSE 4000

CMD ["node", "src/index.js"]
