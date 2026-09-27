export type EstadoTarea = 'pendiente' | 'en_curso' | 'terminada'

export interface Tarea {
  id: number
  orden_id: number
  descripcion: string
  estado: EstadoTarea
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
