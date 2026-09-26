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

export interface MetaPaginacion {
  pagina: number
  por_pagina: number
  total: number
  total_paginas: number
}

export interface PaginaUsuarios {
  usuarios: UsuarioListado[]
  meta: MetaPaginacion
}

export async function listarUsuarios(pagina: number) {
  const { data } = await api.get<PaginaUsuarios>('/usuarios', { params: { pagina } })
  return data
}

export async function crearUsuario(usuario: NuevoUsuario) {
  const { data } = await api.post<UsuarioListado>('/usuarios', { usuario })
  return data
}

export async function resetearPassword(id: number, password: string) {
  await api.patch(`/usuarios/${id}/resetear_password`, { password })
}
