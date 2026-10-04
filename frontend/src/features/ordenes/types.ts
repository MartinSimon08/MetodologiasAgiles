export type EstadoOrden = 'abierta' | 'cerrada'

export interface VehiculoOrden {
  id: number
  patente: string
  marca: string | null
  modelo: string | null
  anio: number | null
}

export interface Orden {
  id: number
  cliente: { id: number; nombre: string; telefono: string; email: string | null }
  vehiculo: VehiculoOrden
  motivo: string
  estado: EstadoOrden
  created_at: string
}

export const ESTADO_ORDEN_LABELS: Record<EstadoOrden, string> = {
  abierta: 'Abierta',
  cerrada: 'Cerrada',
}

export const MOTIVO_LARGO_MAXIMO = 500

export function describirVehiculo(vehiculo: Omit<VehiculoOrden, 'id'>) {
  const detalle = [vehiculo.marca, vehiculo.modelo, vehiculo.anio].filter(Boolean).join(' ')
  return [vehiculo.patente, detalle].filter(Boolean).join(' · ')
}
