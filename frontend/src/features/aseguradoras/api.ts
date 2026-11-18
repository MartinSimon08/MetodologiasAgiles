import { api, type MetaPaginacion } from '../../lib/api'

export interface Aseguradora {
  id: number
  nombre: string
  telefono: string | null
  email: string | null
  activa: boolean
  telegram_vinculada: boolean
  created_at: string
}

export interface DatosAseguradora {
  nombre: string
  telefono: string
  email: string
}

export interface PaginaAseguradoras {
  aseguradoras: Aseguradora[]
  meta: MetaPaginacion
}

export async function listarAseguradoras(buscar: string, pagina: number, soloActivas = false, porPagina?: number) {
  const { data } = await api.get<PaginaAseguradoras>('/aseguradoras', {
    params: { buscar: buscar || undefined, pagina, solo_activas: soloActivas || undefined, por_pagina: porPagina },
  })
  return data
}

export async function guardarAseguradora(aseguradora: DatosAseguradora, id?: number) {
  const { data } = id === undefined
    ? await api.post<Aseguradora>('/aseguradoras', { aseguradora })
    : await api.patch<Aseguradora>(`/aseguradoras/${id}`, { aseguradora })
  return data
}

export async function cambiarEstadoAseguradora(id: number, activa: boolean) {
  const { data } = await api.patch<Aseguradora>(`/aseguradoras/${id}/${activa ? 'activar' : 'desactivar'}`)
  return data
}

export async function eliminarAseguradora(id: number) {
  await api.delete(`/aseguradoras/${id}`)
}

export interface AseguradoraDetalle extends Aseguradora {
  casos: {
    id: number
    numero_siniestro: string
    fecha_turno: string | null
    orden_id: number | null
    asegurado: { id: number; nombre: string }
    vehiculo: { id: number; patente: string; marca: string | null; modelo: string | null }
  }[]
}

export async function obtenerAseguradora(id: number) {
  const { data } = await api.get<AseguradoraDetalle>(`/aseguradoras/${id}`)
  return data
}
