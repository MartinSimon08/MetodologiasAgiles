import { useQueryClient } from '@tanstack/react-query'
import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { cable } from '../../lib/cable'
import { useAuth } from '../auth/AuthContext'
import { describirVehiculo } from '../ordenes/types'
import type { TareaDisponibleAviso } from './types'

const MAX_VISIBLES = 5

export function NotificacionesTareas() {
  const { usuario } = useAuth()
  const queryClient = useQueryClient()
  const [avisos, setAvisos] = useState<TareaDisponibleAviso[]>([])

  useEffect(() => {
    if (usuario?.rol !== 'mecanico') return

    const suscripcion = cable.subscriptions.create(
      { channel: 'TareasChannel' },
      {
        received(aviso: TareaDisponibleAviso) {
          queryClient.invalidateQueries({ queryKey: ['tareas-mecanico'] })
          setAvisos((previos) => [aviso, ...previos].slice(0, MAX_VISIBLES))
        },
      },
    )

    return () => {
      suscripcion.unsubscribe()
    }
  }, [usuario?.rol, queryClient])

  function descartar(id: number) {
    setAvisos((previos) => previos.filter((aviso) => aviso.id !== id))
  }

  if (avisos.length === 0) return null

  return (
    <div className="avisos-tareas" role="status" aria-live="polite">
      {avisos.map((aviso) => (
        <div key={aviso.id} className="aviso-tarea">
          <Link to={`/ordenes/${aviso.orden_id}`} onClick={() => descartar(aviso.id)}>
            <strong>Nueva tarea disponible</strong>
            <span>{aviso.descripcion}</span>
            <span>
              {aviso.cliente} · {describirVehiculo(aviso.vehiculo)}
            </span>
          </Link>
          <button className="secundario" onClick={() => descartar(aviso.id)} aria-label="Descartar aviso">
            ×
          </button>
        </div>
      ))}
    </div>
  )
}
