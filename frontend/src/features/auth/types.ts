export type Rol = 'administrador' | 'mecanico'

export interface Usuario {
  id: number
  nombre: string
  email: string
  rol: Rol
}

export const ROL_LABELS: Record<Rol, string> = {
  administrador: 'Administrador',
  mecanico: 'Mecánico',
}
