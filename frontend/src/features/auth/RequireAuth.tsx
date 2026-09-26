import type { ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from './AuthContext'
import type { Rol } from './types'

interface Props {
  children: ReactNode
  roles?: Rol[]
}

export function RequireAuth({ children, roles }: Props) {
  const { usuario, cargando } = useAuth()
  const location = useLocation()

  if (cargando) return <p className="estado">Cargando…</p>
  if (!usuario) return <Navigate to="/login" replace state={{ desde: location.pathname }} />
  if (roles && !roles.includes(usuario.rol)) return <Navigate to="/" replace />

  return children
}
