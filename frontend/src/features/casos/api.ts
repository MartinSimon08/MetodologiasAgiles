import { api, type MetaPaginacion } from '../../lib/api'

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
