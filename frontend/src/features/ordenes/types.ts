export type EstadoOrden = 'abierta' | 'cerrada'

export interface Orden {
  id: number
  cliente: { id: number; nombre: string; telefono: string; email: string | null }
  vehiculo: string
  estado: EstadoOrden
  created_at: string
}

export const ESTADO_ORDEN_LABELS: Record<EstadoOrden, string> = {
  abierta: 'Abierta',
  cerrada: 'Cerrada',
}
