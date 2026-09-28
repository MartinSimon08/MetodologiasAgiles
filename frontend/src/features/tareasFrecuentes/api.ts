import { api, type MetaPaginacion } from '../../lib/api'

export interface TareaFrecuente {
  id: number
  descripcion: string
  precio_sugerido: number
  created_at: string
}

export interface NuevaTareaFrecuente {
  descripcion: string
  precio_sugerido: number
}

export interface PaginaTareasFrecuentes {
  tareas_frecuentes: TareaFrecuente[]
  meta: MetaPaginacion
}

export async function listarTareasFrecuentes(pagina = 1, porPagina = 100) {
  const { data } = await api.get<PaginaTareasFrecuentes>('/tareas_frecuentes', {
    params: { pagina, por_pagina: porPagina },
  })
  return data
}

export async function crearTareaFrecuente(tarea_frecuente: NuevaTareaFrecuente) {
  const { data } = await api.post<TareaFrecuente>('/tareas_frecuentes', { tarea_frecuente })
  return data
}
