import { api, type MetaPaginacion } from '../../lib/api'
import type { Rol, Usuario } from '../auth/types'

export interface UsuarioListado extends Usuario {
  activo: boolean
  tareas_en_curso: number
  created_at: string
}

export interface TareaLiberada {
  id: number
  orden_id: number
  descripcion: string
}

export interface UsuarioDesactivado extends UsuarioListado {
  tareas_liberadas: TareaLiberada[]
}

export interface NuevoUsuario {
  nombre: string
  email: string
  rol: Rol
  password: string
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

export async function desactivarUsuario(id: number) {
  const { data } = await api.patch<UsuarioDesactivado>(`/usuarios/${id}/desactivar`)
  return data
}
