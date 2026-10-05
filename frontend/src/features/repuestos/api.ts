import { api, type MetaPaginacion } from '../../lib/api'

export interface RepuestoCatalogo {
  id: number
  nombre: string
  precio: string
}

export interface Repuesto {
  id: number
  descripcion: string
  cantidad: number
  costo_unitario: string
  margen: string
  precio_cliente: string
  ganancia: string
  proveedor: string | null
  created_at: string
  registrado_por: { id: number; nombre: string }
}

export interface NuevoRepuesto {
  repuesto_catalogo_id?: number
  descripcion: string
  cantidad: string
  costo_unitario: string
  margen?: string
  proveedor?: string
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

export interface VistaPreviaRepuesto {
  precio_cliente: string
  ganancia: string
  margen: string
}

export async function listarRepuestos(ordenId: number, pagina: number) {
  const { data } = await api.get<{ repuestos: Repuesto[]; meta: MetaPaginacion }>(
    `/ordenes/${ordenId}/repuestos`, { params: { pagina } },
  )
  return data
}

export async function previsualizarRepuesto(ordenId: number, repuesto: NuevoRepuesto, signal?: AbortSignal) {
  const { data } = await api.post<VistaPreviaRepuesto>(
    `/ordenes/${ordenId}/repuestos/vista_previa`, { repuesto }, { signal },
  )
  return data
}

export async function agregarRepuesto(ordenId: number, repuesto: NuevoRepuesto) {
  const { data } = await api.post<Repuesto>(`/ordenes/${ordenId}/repuestos`, { repuesto })
  return data
}
