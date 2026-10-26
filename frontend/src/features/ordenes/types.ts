import type { AprobacionTarea, EstadoTarea } from '../tareas/types'
import type { AprobacionRepuesto } from '../repuestos/api'

export type EstadoOrden = 'abierta' | 'cerrada' | 'cancelada'

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
  cancelada_en: string | null
  cerrada_en: string | null
  cerrada_por: { id: number; nombre: string } | null
  total_cerrado?: string | null
}

export interface OrdenCancelada extends Orden {
  tareas_liberadas: { id: number; descripcion: string }[]
}

export interface ResumenCierre {
  orden_id: number
  estado: EstadoOrden
  tareas: {
    id: number
    descripcion: string
    estado: EstadoTarea
    aprobacion: AprobacionTarea
    precio: string | null
    terminada_en: string | null
    mecanico: { id: number; nombre: string } | null
  }[]
  repuestos: {
    id: number
    descripcion: string
    cantidad: number
    estado: 'valorizado' | 'pendiente_de_valorizar'
    aprobacion: AprobacionRepuesto
    precio_cliente: string | null
  }[]
  mano_de_obra: string
  total_repuestos: string
  total: string
  adelantado: string
  saldo: string
}

export interface TotalParcial {
  orden_id: number
  tareas: ResumenCierre['tareas']
  repuestos: {
    id: number
    descripcion: string
    cantidad: number
    estado: 'valorizado' | 'pendiente_de_valorizar'
    aprobacion: AprobacionRepuesto
    costo_unitario: string | null
    margen: string | null
    precio_cliente: string | null
  }[]
  mano_de_obra: string
  total_repuestos: string
  total: string
  a_cobrar_hoy: string
}

export interface Presupuesto {
  orden_id: number
  tareas: ResumenCierre['tareas']
  repuestos: {
    id: number
    descripcion: string
    cantidad: number
    estado: 'valorizado' | 'pendiente_de_valorizar'
    aprobacion: AprobacionRepuesto
    precio_cliente: string | null
  }[]
  presupuesto: string
  total_aseguradora: string
}

export const ESTADO_ORDEN_LABELS: Record<EstadoOrden, string> = {
  abierta: 'Abierta',
  cerrada: 'Cerrada',
  cancelada: 'Cancelada',
}

export const MOTIVO_LARGO_MAXIMO = 500

export function describirVehiculo(vehiculo: Omit<VehiculoOrden, 'id'>) {
  const detalle = [vehiculo.marca, vehiculo.modelo, vehiculo.anio].filter(Boolean).join(' ')
  return [vehiculo.patente, detalle].filter(Boolean).join(' · ')
}
