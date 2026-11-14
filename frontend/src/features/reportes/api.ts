import { api } from '../../lib/api'

export interface FilaReporteMecanico {
  mecanico: { id: number; nombre: string }
  tomadas: number
  completadas: number
}

export interface ReporteTareasPorMecanico {
  mecanicos: FilaReporteMecanico[]
}

export async function obtenerReporteTareasPorMecanico(filtros: { desde: string; hasta: string }) {
  const { data } = await api.get<ReporteTareasPorMecanico>('/reportes/tareas_por_mecanico', {
    params: { desde: filtros.desde, hasta: filtros.hasta },
  })
  return data
}

export interface ReporteMargenRepuestos {
  margen_total: string
}

export async function obtenerReporteMargenRepuestos(filtros: { desde: string; hasta: string }) {
  const { data } = await api.get<ReporteMargenRepuestos>('/reportes/margen_repuestos', {
    params: { desde: filtros.desde, hasta: filtros.hasta },
  })
  return data
}

export interface FilaTareaFrecuente {
  descripcion: string
  cantidad: number
}

export interface ReporteTareasFrecuentes {
  tareas: FilaTareaFrecuente[]
}

export async function obtenerReporteTareasFrecuentes() {
  const { data } = await api.get<ReporteTareasFrecuentes>('/reportes/tareas_frecuentes')
  return data
}

export interface ReporteOrdenesPorPeriodo {
  abiertas: number
  cerradas: number
}

export async function obtenerReporteOrdenesPorPeriodo(filtros: { desde: string; hasta: string }) {
  const { data } = await api.get<ReporteOrdenesPorPeriodo>('/reportes/ordenes_por_periodo', {
    params: { desde: filtros.desde, hasta: filtros.hasta },
  })
  return data
}
