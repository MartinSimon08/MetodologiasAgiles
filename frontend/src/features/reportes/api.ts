import { api } from '../../lib/api'

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
