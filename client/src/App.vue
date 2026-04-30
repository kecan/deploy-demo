<template>
  <div class="container">
    <h1>📝 Todo List</h1>

    <div v-if="error" class="error">
      {{ error }}
    </div>

    <div class="add-todo">
      <input
        v-model="newTodo"
        @keyup.enter="addTodo"
        placeholder="添加新任务..."
        :disabled="loading"
      />
      <button @click="addTodo" :disabled="loading || !newTodo.trim()">
        添加
      </button>
    </div>

    <div class="todo-list">
      <div v-if="loading" class="loading">加载中...</div>

      <template v-else-if="todos.length">
        <div
          v-for="todo in todos"
          :key="todo.id"
          class="todo-item"
        >
          <input
            type="checkbox"
            :checked="todo.completed"
            @change="toggleTodo(todo)"
          />
          <span :class="{ completed: todo.completed }">
            {{ todo.title }}
          </span>
          <button @click="deleteTodo(todo.id)">删除</button>
        </div>

        <div class="stats">
          <span>总计: {{ todos.length }} 项</span>
          <span>已完成: {{ completedCount }} 项</span>
        </div>
      </template>

      <div v-else class="empty-state">
        暂无任务，添加一个吧！
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const API_BASE = '/api'

const todos = ref([])
const newTodo = ref('')
const loading = ref(true)
const error = ref('')

const completedCount = computed(() =>
  todos.value.filter(t => t.completed).length
)

async function fetchTodos() {
  try {
    loading.value = true
    error.value = ''
    const res = await fetch(`${API_BASE}/todos`)
    if (!res.ok) throw new Error('获取数据失败')
    todos.value = await res.json()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function addTodo() {
  if (!newTodo.value.trim()) return

  try {
    error.value = ''
    const res = await fetch(`${API_BASE}/todos`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: newTodo.value.trim() })
    })
    if (!res.ok) throw new Error('添加失败')
    const todo = await res.json()
    todos.value.push(todo)
    newTodo.value = ''
  } catch (e) {
    error.value = e.message
  }
}

async function toggleTodo(todo) {
  try {
    error.value = ''
    const res = await fetch(`${API_BASE}/todos/${todo.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ completed: !todo.completed })
    })
    if (!res.ok) throw new Error('更新失败')
    const updated = await res.json()
    const index = todos.value.findIndex(t => t.id === todo.id)
    if (index !== -1) todos.value[index] = updated
  } catch (e) {
    error.value = e.message
  }
}

async function deleteTodo(id) {
  try {
    error.value = ''
    const res = await fetch(`${API_BASE}/todos/${id}`, {
      method: 'DELETE'
    })
    if (!res.ok) throw new Error('删除失败')
    todos.value = todos.value.filter(t => t.id !== id)
  } catch (e) {
    error.value = e.message
  }
}

onMounted(fetchTodos)
</script>
