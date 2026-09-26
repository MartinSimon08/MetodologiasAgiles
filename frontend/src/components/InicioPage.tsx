import { Navigate } from 'react-router-dom'
import { useAuth } from '../features/auth/AuthContext'

export function InicioPage() {
  const { usuario } = useAuth()

  if (usuario?.rol === 'administrador') return <Navigate to="/usuarios" replace />

  return (
    <section>
      <h1>Hola, {usuario?.nombre}</h1>
      <p className="estado">Acá vas a ver las tareas disponibles para tomar.</p>
    </section>
  )
}
