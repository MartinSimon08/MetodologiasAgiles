import { api } from '../../lib/api'
import type { Usuario } from './types'

export async function iniciarSesion(email: string, password: string) {
  const { data } = await api.post<{ token: string }>('/sesion', { email, password })
  return data.token
}

export async function obtenerSesion() {
  const { data } = await api.get<Usuario>('/sesion')
  return data
}
