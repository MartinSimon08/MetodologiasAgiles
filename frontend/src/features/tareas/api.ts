import { api, type MetaPaginacion } from '../../lib/api'
import type { Tarea } from './types'

export interface PaginaTareas {
  tareas: Tarea[]
  meta: MetaPaginacion
}

export async function listarTareas(ordenId: number, pagina: number) {
  const { data } = await api.get<PaginaTareas>(`/ordenes/${ordenId}/tareas`, { params: { pagina } })
  return data
}

export async function crearTarea(ordenId: number, descripcion: string, precio: string) {
  const { data } = await api.post<Tarea>(`/ordenes/${ordenId}/tareas`, {
    tarea: { descripcion, precio: precio ? Number(precio) : null },
  })
  return data
}

export async function tomarTarea(id: number) {
  const { data } = await api.patch<Tarea>(`/tareas/${id}/tomar`)
  return data
}

export async function completarTarea(id: number) {
  const { data } = await api.patch<Tarea>(`/tareas/${id}/completar`)
  return data
}

export async function liberarTarea(id: number) {
  const { data } = await api.patch<Tarea>(`/tareas/${id}/liberar`)
  return data
}
