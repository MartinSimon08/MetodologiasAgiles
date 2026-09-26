import { api } from '../../lib/api'
import type { Rol, Usuario } from '../auth/types'

export interface UsuarioListado extends Usuario {
  created_at: string
}

export interface NuevoUsuario {
  nombre: string
  email: string
  rol: Rol
  password: string
}

export async function listarUsuarios() {
  const { data } = await api.get<UsuarioListado[]>('/usuarios')
  return data
}

export async function crearUsuario(usuario: NuevoUsuario) {
  const { data } = await api.post<UsuarioListado>('/usuarios', { usuario })
  return data
}

export async function resetearPassword(id: number, password: string) {
  await api.patch(`/usuarios/${id}/resetear_password`, { password })
}
