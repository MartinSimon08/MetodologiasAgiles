import type { ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from './AuthContext'
import type { Rol } from './types'
import { Cargando } from '../../components/Cargando'

interface Props {
  children: ReactNode
  roles?: Rol[]
}

export function RequireAuth({ children, roles }: Props) {
  const { usuario, cargando } = useAuth()

  if (cargando) return <Cargando pantalla />
  if (!usuario) return <Navigate to="/login" replace />
  if (roles && !roles.includes(usuario.rol)) return <Navigate to="/" replace />

  return children
}
