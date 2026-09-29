import { Navigate } from 'react-router-dom'
import { useAuth } from '../features/auth/AuthContext'

export function InicioPage() {
  const { usuario } = useAuth()
  return <Navigate to={usuario?.rol === 'mecanico' ? '/mis-tareas' : '/ordenes'} replace />
}
