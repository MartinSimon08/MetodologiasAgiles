export type EstadoOrden = 'abierta' | 'cerrada'

export interface Orden {
  id: number
  cliente: string
  vehiculo: string
  estado: EstadoOrden
  created_at: string
}

export const ESTADO_ORDEN_LABELS: Record<EstadoOrden, string> = {
  abierta: 'Abierta',
  cerrada: 'Cerrada',
}
