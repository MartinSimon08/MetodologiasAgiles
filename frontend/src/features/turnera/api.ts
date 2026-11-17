import { api } from '../../lib/api'

export type EstadoTurno = 'turno_asignado' | 'ingresado' | 'listo_para_retirar'

export const ESTADO_TURNO_LABELS: Record<EstadoTurno, string> = {
  turno_asignado: 'Turno asignado',
  ingresado: 'Ingresado',
  listo_para_retirar: 'Listo para retirar',
}

export interface Turno {
  caso_id: number
  numero_siniestro: string
  estado: EstadoTurno
  orden_id: number | null
  aseguradora: { id: number; nombre: string }
  asegurado: { id: number; nombre: string; telefono: string }
  vehiculo: { id: number; patente: string; marca: string | null; modelo: string | null }
}

export interface DiaTurnera {
  fecha: string
  ingresos: number
  supera_cupo: boolean
  turnos: Turno[]
}

export type PeriodoTurnera = 'semana' | 'mes'

export interface Turnera {
  periodo: PeriodoTurnera
  desde: string
  hasta: string
  cupo_diario: number
  dias: DiaTurnera[]
}

export async function obtenerTurnera(fecha: string | undefined, periodo: PeriodoTurnera) {
  const { data } = await api.get<Turnera>('/turnera', { params: { fecha, periodo } })
  return data
}
