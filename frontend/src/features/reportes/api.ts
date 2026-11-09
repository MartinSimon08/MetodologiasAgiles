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
