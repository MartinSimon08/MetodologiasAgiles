import type { ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from './AuthContext'
import type { Rol } from './types'

interface Props {
  children: ReactNode
  roles?: Rol[]
}

export function RequireAuth({ children, roles }: Props) {
  const { usuario, cargando } = useAuth()

  if (cargando) return <p className="estado">Cargando…</p>
  if (!usuario) return <Navigate to="/login" replace />
  if (roles && !roles.includes(usuario.rol)) return <Navigate to="/" replace />

  return children
}
