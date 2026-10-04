import { api, type MetaPaginacion } from '../../lib/api'
import type { Orden } from './types'

export interface PaginaOrdenes {
  ordenes: Orden[]
  meta: MetaPaginacion
}

export async function listarOrdenes(pagina: number) {
  const { data } = await api.get<PaginaOrdenes>('/ordenes', { params: { pagina } })
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
