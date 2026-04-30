import express from 'express'
import cors from 'cors'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const app = express()
const PORT = process.env.PORT || 4000

// 数据文件路径
const dataDir = join(__dirname, '../data')
const dataFile = join(dataDir, 'todos.json')

// 确保数据目录存在
if (!existsSync(dataDir)) {
  mkdirSync(dataDir, { recursive: true })
}

// 读取数据
function readTodos() {
  if (!existsSync(dataFile)) {
    return []
  }
  try {
    const data = readFileSync(dataFile, 'utf-8')
    return JSON.parse(data)
  } catch {
    return []
  }
}

// 写入数据
function writeTodos(todos) {
  writeFileSync(dataFile, JSON.stringify(todos, null, 2))
}

// 生成 ID
function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2)
}

// 中间件
app.use(cors())
app.use(express.json())

// 静态文件服务 (生产环境)
const clientDistPath = join(__dirname, '../../client/dist')
app.use(express.static(clientDistPath))

// API 路由

// 获取所有 todos
app.get('/api/todos', (req, res) => {
  try {
    const todos = readTodos()
    res.json(todos)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// 创建 todo
app.post('/api/todos', (req, res) => {
  try {
    const { title } = req.body
    if (!title || !title.trim()) {
      return res.status(400).json({ error: '标题不能为空' })
    }

    const todos = readTodos()
    const newTodo = {
      id: generateId(),
      title: title.trim(),
      completed: false,
      createdAt: new Date().toISOString()
    }
    todos.unshift(newTodo)
    writeTodos(todos)

    res.status(201).json(newTodo)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// 更新 todo
app.put('/api/todos/:id', (req, res) => {
  try {
    const { id } = req.params
    const { title, completed } = req.body

    const todos = readTodos()
    const index = todos.findIndex(t => t.id === id)

    if (index === -1) {
      return res.status(404).json({ error: 'Todo 不存在' })
    }

    if (title !== undefined) {
      todos[index].title = title
    }
    if (completed !== undefined) {
      todos[index].completed = completed
    }

    writeTodos(todos)
    res.json(todos[index])
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// 删除 todo
app.delete('/api/todos/:id', (req, res) => {
  try {
    const { id } = req.params
    const todos = readTodos()
    const index = todos.findIndex(t => t.id === id)

    if (index === -1) {
      return res.status(404).json({ error: 'Todo 不存在' })
    }

    todos.splice(index, 1)
    writeTodos(todos)

    res.status(204).send()
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// 健康检查
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() })
})

// SPA 回退路由
app.get('*', (req, res) => {
  res.sendFile(join(clientDistPath, 'index.html'))
})

app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`)
  console.log(`📁 Static files from: ${clientDistPath}`)
  console.log(`🗄️  Data file: ${dataFile}`)
})
