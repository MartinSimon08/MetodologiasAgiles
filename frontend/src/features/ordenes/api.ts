import { api, type MetaPaginacion } from '../../lib/api'
import type {
  ComprobanteOrden,
  CorreccionOrden,
  EnvioPresupuesto,
  EstadoOrden,
  Orden,
  OrdenCancelada,
  Presupuesto,
  ResumenCierre,
  TotalParcial,
} from './types'

export interface PaginaOrdenes {
  ordenes: Orden[]
  meta: MetaPaginacion
}

export async function listarOrdenes(pagina: number, estado?: EstadoOrden, q?: string, porPagina?: number) {
  const { data } = await api.get<PaginaOrdenes>('/ordenes', {
    params: { pagina, estado, q: q || undefined, por_pagina: porPagina },
  })
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

export async function obtenerResumenCierre(id: number) {
  const { data } = await api.get<ResumenCierre>(`/ordenes/${id}/resumen_cierre`)
  return data
}

export async function obtenerTotalParcial(id: number) {
  const { data } = await api.get<TotalParcial>(`/ordenes/${id}/total_parcial`)
  return data
}

export async function obtenerPresupuesto(id: number) {
  const { data } = await api.get<Presupuesto>(`/ordenes/${id}/presupuesto`)
  return data
}

export async function enviarPresupuesto(id: number, medio: 'email' | 'telegram') {
  const { data } = await api.post<EnvioPresupuesto>(`/ordenes/${id}/enviar_presupuesto`, { medio })
  return data
}

export async function cerrarOrden(id: number, descartarPendientes: boolean, franquicia?: string) {
  const { data } = await api.patch<Orden>(`/ordenes/${id}/cerrar`, {
    descartar_pendientes: descartarPendientes,
    franquicia: franquicia?.trim() ? franquicia.trim() : null,
  })
  return data
}

export interface DatosCorreccion {
  motivo: string
  totalCerrado?: string
  franquicia?: string
  confirmarRevision: boolean
}

export async function corregirOrden(id: number, datos: DatosCorreccion) {
  const { data } = await api.patch<Orden>(`/ordenes/${id}/corregir`, {
    motivo: datos.motivo,
    total_cerrado: datos.totalCerrado,
    franquicia: datos.franquicia,
    confirmar_revision: datos.confirmarRevision,
  })
  return data
}

export async function listarCorrecciones(id: number) {
  const { data } = await api.get<{ correcciones: CorreccionOrden[] }>(`/ordenes/${id}/correcciones`)
  return data.correcciones
}

export async function obtenerComprobante(id: number) {
  const { data } = await api.get<ComprobanteOrden>(`/ordenes/${id}/comprobante`)
  return data
}
