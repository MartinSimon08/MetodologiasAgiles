import axios from 'axios'

const TOKEN_KEY = 'taller.token'

export const tokenStorage = {
  get: () => localStorage.getItem(TOKEN_KEY),
  set: (token: string) => localStorage.setItem(TOKEN_KEY, token),
  clear: () => localStorage.removeItem(TOKEN_KEY),
}

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? 'http://localhost:3000',
})

api.interceptors.request.use((config) => {
  const token = tokenStorage.get()
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

let unauthorizedHandler: (() => void) | null = null

export function onUnauthorized(handler: () => void) {
  unauthorizedHandler = handler
  return () => {
    if (unauthorizedHandler === handler) unauthorizedHandler = null
  }
}

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (axios.isAxiosError(error) && error.response?.status === 401 && tokenStorage.get()) {
      tokenStorage.clear()
      unauthorizedHandler?.()
    }
    return Promise.reject(error)
  },
)

export type FieldErrors = Record<string, string[]>

export function fieldErrors(error: unknown): FieldErrors {
  if (axios.isAxiosError(error) && error.response?.data?.errors) {
    return error.response.data.errors as FieldErrors
  }
  return {}
}

export function errorMessage(error: unknown, fallback = 'Ocurrió un error. Probá de nuevo.') {
  if (axios.isAxiosError(error)) {
    if (!error.response) return 'No se pudo conectar con el servidor.'
    if (typeof error.response.data?.error === 'string') return error.response.data.error
    if (error.response.status === 403) return 'No tenés permiso para hacer esto.'
  }
  return fallback
}
