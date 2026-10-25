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

export type TipoAjuste = 'devolucion' | 'cambio'

export interface AjusteRepuesto {
  id: number
  tipo: TipoAjuste
  cantidad: number
  costo_unitario: string
  ajuste_costo: string
  ajuste_precio_cliente: string
  precio_original: string
  motivo: string
  registrado_en: string
  registrado_por: { id: number; nombre: string }
}

export interface Repuesto {
  id: number
  descripcion: string
  cantidad: number
  estado: EstadoRepuesto
  costo_unitario?: string | null
  margen?: string | null
  precio_cliente?: string | null
  ganancia?: string | null
  precio_vigente?: string | null
  costo_vigente?: string | null
  ganancia_vigente?: string | null
  cantidad_disponible?: number
  ajustes?: AjusteRepuesto[]
  proveedor?: string | null
  created_at: string
  quitado_en?: string | null
  registrado_por: { id: number; nombre: string }
  quitado_por?: { id: number; nombre: string } | null
  comprobante: Comprobante | null
}

export interface Comprobante {
  nombre: string
  content_type: string
  byte_size: number
}

export interface CambiosRepuesto {
  cantidad: string
  costo_unitario?: string
  margen?: string
  proveedor?: string
}

export interface NuevoRepuesto {
  repuesto_catalogo_id?: number
  descripcion: string
  cantidad: string
  costo_unitario: string
  margen?: string
  proveedor?: string
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

export interface VistaPreviaRepuesto {
  precio_cliente: string
  ganancia: string
  margen: string
}

export async function listarRepuestos(ordenId: number, pagina: number) {
  const { data } = await api.get<{ repuestos: Repuesto[]; quitados?: Repuesto[]; meta: MetaPaginacion }>(
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

export async function avisarRepuesto(ordenId: number, repuesto: AvisoRepuesto) {
  const { data } = await api.post<Repuesto>(`/ordenes/${ordenId}/repuestos`, { repuesto })
  return data
}

export async function valorizarRepuesto(ordenId: number, id: number, repuesto: ValorizarRepuesto) {
  const { data } = await api.patch<Repuesto>(`/ordenes/${ordenId}/repuestos/${id}/valorizar`, { repuesto })
  return data
}

export async function editarRepuesto(ordenId: number, id: number, repuesto: CambiosRepuesto) {
  const { data } = await api.patch<Repuesto>(`/ordenes/${ordenId}/repuestos/${id}`, { repuesto })
  return data
}

export async function quitarRepuesto(ordenId: number, id: number) {
  const { data } = await api.delete<Repuesto>(`/ordenes/${ordenId}/repuestos/${id}`)
  return data
}

export interface CompraPorProveedor {
  proveedor: string | null
  total_comprado: string
  cantidad_compras: number
}

export interface RepuestoPorProveedor {
  id: number
  descripcion: string
  cantidad: number
  costo_unitario: string
  total_costo: string
  proveedor: string | null
  created_at: string
  orden_id: number
  orden: {
    id: number
    cliente: string
    vehiculo: { id: number; patente: string; marca: string | null; modelo: string | null; anio: number | null }
  }
}

export interface PaginaRepuestosPorProveedor {
  proveedores: CompraPorProveedor[]
  total_comprado: string
  repuestos: RepuestoPorProveedor[]
  meta: MetaPaginacion
}

export function nombreProveedor(proveedor: string | null) {
  return proveedor?.trim() ? proveedor : 'Sin proveedor'
}

export async function listarRepuestosPorProveedor(filtros: {
  proveedor?: string
  desde?: string
  hasta?: string
  pagina: number
}) {
  const { data } = await api.get<PaginaRepuestosPorProveedor>('/repuestos_por_proveedor', {
    params: {
      pagina: filtros.pagina,
      ...(filtros.proveedor ? { proveedor: filtros.proveedor } : {}),
      ...(filtros.desde ? { desde: filtros.desde } : {}),
      ...(filtros.hasta ? { hasta: filtros.hasta } : {}),
    },
  })
  return data
}

export async function adjuntarComprobante(ordenId: number, id: number, archivo: File) {
  const form = new FormData()
  form.append('comprobante', archivo)
  const { data } = await api.post<Repuesto>(`/ordenes/${ordenId}/repuestos/${id}/comprobante`, form)
  return data
}

export async function verComprobante(ordenId: number, id: number) {
  const { data } = await api.get<Blob>(`/ordenes/${ordenId}/repuestos/${id}/comprobante`, { responseType: 'blob' })
  return data
}

export interface NuevoAjuste {
  tipo: TipoAjuste
  cantidad: string
  costo_unitario: string
  motivo: string
}

export async function registrarAjuste(ordenId: number, repuestoId: number, ajuste: NuevoAjuste) {
  const { data } = await api.post<AjusteRepuesto>(
    `/ordenes/${ordenId}/repuestos/${repuestoId}/ajustes`,
    { ajuste },
  )
  return data
}
