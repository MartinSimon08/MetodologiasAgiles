import { api, type MetaPaginacion } from '../../lib/api'
import type { Aseguradora } from '../aseguradoras/api'

export const NUMERO_SINIESTRO_MAXIMO = 50
export const DESCRIPCION_MAXIMA = 1000

export interface Caso {
  id: number
  numero_siniestro: string
  descripcion: string | null
  fecha_turno: string | null
  orden_id: number | null
  created_at: string
  aseguradora: { id: number; nombre: string }
  asegurado: { id: number; nombre: string; telefono: string }
  vehiculo: { id: number; patente: string; marca: string | null; modelo: string | null }
  cambios_turno: CambioTurno[]
}

export interface CambioTurno {
  id: number
  fecha_anterior: string | null
  fecha_nueva: string
  created_at: string
  registrado_por: { id: number; nombre: string }
}

export interface NuevoCaso {
  aseguradora_id: number | null
  asegurado_id: number | null
  vehiculo_id: number | null
  numero_siniestro: string
  descripcion: string
}

export interface PaginaCasos {
  casos: Caso[]
  meta: MetaPaginacion
}

export async function listarCasos(buscar: string, pagina: number) {
  const { data } = await api.get<PaginaCasos>('/casos', { params: { buscar: buscar || undefined, pagina } })
  return data
}

export async function abrirCaso(caso: NuevoCaso) {
  const { data } = await api.post<Caso>('/casos', { caso })
  return data
}

export interface CasoAseguradora {
  id: number
  numero_siniestro: string
  orden_id: number | null
  orden_estado: 'abierta' | 'cerrada' | 'cancelada' | null
  created_at: string
  asegurado: { id: number; nombre: string }
  vehiculo: { id: number; patente: string; marca: string | null; modelo: string | null }
  total_autorizado: string
  franquicia_cobrada: string
  saldo_pendiente: string
}

export interface TotalesCasosAseguradora {
  total_autorizado: string
  franquicia_cobrada: string
  saldo_pendiente: string
}

export interface ConsultaCasosAseguradora {
  aseguradora: Aseguradora
  casos: CasoAseguradora[]
  totales: TotalesCasosAseguradora
}

export async function consultarCasosAseguradora(filtros: { aseguradoraId: number; desde: string; hasta: string }) {
  const { data } = await api.get<ConsultaCasosAseguradora>('/casos/aseguradora', {
    params: { aseguradora_id: filtros.aseguradoraId, desde: filtros.desde, hasta: filtros.hasta },
  })
  return data
}

export async function ingresarCaso(id: number) {
  const { data } = await api.post<Caso>(`/casos/${id}/ingresar`)
  return data
}

export async function asignarTurno(id: number, fechaTurno: string) {
  const { data } = await api.patch<Caso>(`/casos/${id}/turno`, { caso: { fecha_turno: fechaTurno } })
  return data
}

export function hoyIso() {
  const hoy = new Date()
  const mes = String(hoy.getMonth() + 1).padStart(2, '0')
  const dia = String(hoy.getDate()).padStart(2, '0')
  return `${hoy.getFullYear()}-${mes}-${dia}`
}

export function fechaCorta(iso: string) {
  const [anio, mes, dia] = iso.split('-').map(Number)
  return new Date(anio, mes - 1, dia).toLocaleDateString('es-AR', {
    weekday: 'short',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })
}
