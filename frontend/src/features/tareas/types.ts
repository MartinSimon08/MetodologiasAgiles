import type { VehiculoOrden } from '../ordenes/types'

export type EstadoTarea = 'pendiente' | 'en_curso' | 'terminada'

export interface Nota {
  id: number
  contenido: string
  registrado_por: { id: number; nombre: string }
  created_at: string
}

export interface Tarea {
  id: number
  orden_id: number
  descripcion: string
  estado: EstadoTarea
  precio?: number | null
  mecanico_id: number | null
  mecanico: { id: number; nombre: string } | null
  tomada_en: string | null
  terminada_en: string | null
  created_at: string
  notas: Nota[]
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
  notas: Nota[]
}

export interface TareasMecanico {
  mias: TareaMecanico[]
  disponibles: TareaMecanico[]
}

export interface TareaDisponibleAviso {
  id: number
  descripcion: string
  orden_id: number
  cliente: string
  vehiculo: { id: number; patente: string; marca: string | null; modelo: string | null; anio: number | null }
}
