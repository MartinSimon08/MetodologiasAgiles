import type { VehiculoOrden } from '../ordenes/types'

export type EstadoTarea = 'pendiente' | 'en_curso' | 'terminada'

export interface Tarea {
  id: number
  orden_id: number
  descripcion: string
  estado: EstadoTarea
  precio: number | null
  mecanico_id: number | null
  mecanico: { id: number; nombre: string } | null
  tomada_en: string | null
  terminada_en: string | null
  created_at: string
}

export const ESTADO_TAREA_LABELS: Record<EstadoTarea, string> = {
  pendiente: 'Pendiente',
  en_curso: 'En curso',
  terminada: 'Terminada',
}

export interface TareaMecanico {
  id: number
  orden_id: number
  descripcion: string
  estado: EstadoTarea
  mecanico_id: number | null
  tomada_en: string | null
  created_at: string
  orden: { id: number; vehiculo: VehiculoOrden; cliente: string }
}

export interface TareasMecanico {
  mias: TareaMecanico[]
  disponibles: TareaMecanico[]
}
