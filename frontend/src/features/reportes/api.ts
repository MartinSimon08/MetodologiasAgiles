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

export interface ReporteIngresos {
  franquicia_cobrada: string
  saldo_facturado_aseguradoras: string
  saldo_pendiente_aseguradoras: string
  ingresos_clientes_directos: string
  total_ingresos: string
}

export async function obtenerReporteIngresos(filtros: { desde: string; hasta: string }) {
  const { data } = await api.get<ReporteIngresos>('/reportes/ingresos', {
    params: { desde: filtros.desde, hasta: filtros.hasta },
  })
  return data
}
