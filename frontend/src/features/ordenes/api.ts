import { api, type MetaPaginacion } from '../../lib/api'
import type { EstadoOrden, Orden, OrdenCancelada } from './types'

export interface PaginaOrdenes {
  ordenes: Orden[]
  meta: MetaPaginacion
}

export async function listarOrdenes(pagina: number, estado?: EstadoOrden) {
  const { data } = await api.get<PaginaOrdenes>('/ordenes', { params: { pagina, estado } })
  return data
}

export async function obtenerOrden(id: number) {
  const { data } = await api.get<Orden>(`/ordenes/${id}`)
  return data
}

export async function abrirOrden(vehiculoId: number | null, motivo: string) {
  const { data } = await api.post<Orden>('/ordenes', { orden: { vehiculo_id: vehiculoId, motivo } })
  return data
}

export async function cancelarOrden(id: number) {
  const { data } = await api.patch<OrdenCancelada>(`/ordenes/${id}/cancelar`)
  return data
}
