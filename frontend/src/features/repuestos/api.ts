import { api, type MetaPaginacion } from '../../lib/api'

export interface RepuestoCatalogo {
  id: number
  nombre: string
  precio: string
}

export type EstadoRepuesto = 'pendiente_de_valorizar' | 'valorizado'

export const ESTADO_REPUESTO_LABELS: Record<EstadoRepuesto, string> = {
  pendiente_de_valorizar: 'Pendiente de valorizar',
  valorizado: 'Valorizado',
}

export interface Repuesto {
  id: number
  descripcion: string
  cantidad: number
  estado: EstadoRepuesto
  costo_unitario: string | null
  margen: string | null
  precio_cliente: string | null
  ganancia: string | null
}

export interface NuevoRepuesto {
  repuesto_catalogo_id?: number
  descripcion: string
  cantidad: string
  costo_unitario: string
  margen?: string
  proveedor: string
}

export interface AvisoRepuesto {
  descripcion: string
  cantidad: string
}

export interface ValorizarRepuesto {
  costo_unitario: string
  margen?: string
}

export async function guardarCatalogo(repuesto: { nombre: string; precio: string }, id?: number) {
  const { data } = id === undefined
    ? await api.post<RepuestoCatalogo>('/repuestos_catalogo', { repuesto_catalogo: repuesto })
    : await api.patch<RepuestoCatalogo>(`/repuestos_catalogo/${id}`, { repuesto_catalogo: repuesto })
  return data
}

export async function listarCatalogo(buscar: string, pagina: number) {
  const { data } = await api.get<{ repuestos: RepuestoCatalogo[]; meta: MetaPaginacion }>(
    '/repuestos_catalogo', { params: { buscar, pagina } },
  )
  return data
}

export async function eliminarCatalogo(id: number) {
  await api.delete(`/repuestos_catalogo/${id}`)
}

export async function listarRepuestos(ordenId: number, pagina: number) {
  const { data } = await api.get<{ repuestos: Repuesto[]; meta: MetaPaginacion }>(
    `/ordenes/${ordenId}/repuestos`, { params: { pagina } },
  )
  return data
}

export async function agregarRepuesto(ordenId: number, repuesto: NuevoRepuesto) {
  const { data } = await api.post<Repuesto>(`/ordenes/${ordenId}/repuestos`, { repuesto })
  return data
}

export async function avisarRepuesto(ordenId: number, repuesto: AvisoRepuesto) {
  const { data } = await api.post<Repuesto>(`/ordenes/${ordenId}/repuestos`, { repuesto })
  return data
}

export async function valorizarRepuesto(ordenId: number, id: number, repuesto: ValorizarRepuesto) {
  const { data } = await api.patch<Repuesto>(`/ordenes/${ordenId}/repuestos/${id}/valorizar`, { repuesto })
  return data
}
