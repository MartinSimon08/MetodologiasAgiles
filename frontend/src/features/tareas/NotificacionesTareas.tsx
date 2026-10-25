import { useQueryClient } from '@tanstack/react-query'
import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { cable } from '../../lib/cable'
import { useAuth } from '../auth/AuthContext'
import { describirVehiculo } from '../ordenes/types'
import type { AvisoTarea } from './types'

const MAX_VISIBLES = 5

interface AvisoConClave {
  clave: number
  aviso: AvisoTarea
}

export function NotificacionesTareas() {
  const { usuario } = useAuth()
  const queryClient = useQueryClient()
  const [avisos, setAvisos] = useState<AvisoConClave[]>([])
  const proximaClave = useRef(0)

  useEffect(() => {
    if (usuario?.rol !== 'mecanico') return

    const suscripcion = cable.subscriptions.create(
      { channel: 'TareasChannel' },
      {
        received(aviso: AvisoTarea) {
          queryClient.invalidateQueries({ queryKey: ['tareas-mecanico'] })
          const clave = proximaClave.current++
          setAvisos((previos) => [{ clave, aviso }, ...previos].slice(0, MAX_VISIBLES))
        },
      },
    )

    return () => {
      suscripcion.unsubscribe()
    }
  }, [usuario?.rol, queryClient])

  function descartar(clave: number) {
    setAvisos((previos) => previos.filter((item) => item.clave !== clave))
  }

  if (avisos.length === 0) return null

  return (
    <div className="avisos-tareas" role="status" aria-live="polite">
      {avisos.map(({ clave, aviso }) => (
        <div key={clave} className="aviso-tarea">
          <Link to={`/ordenes/${aviso.orden_id}`} onClick={() => descartar(clave)}>
            {aviso.tipo === 'tarea_rechazada' ? (
              <>
                <strong>Te rechazaron una tarea</strong>
                <span>{aviso.descripcion}</span>
              </>
            ) : (
              <>
                <strong>Nueva tarea disponible</strong>
                <span>{aviso.descripcion}</span>
                <span>
                  {aviso.cliente} · {describirVehiculo(aviso.vehiculo)}
                </span>
              </>
            )}
          </Link>
          <button className="secundario" onClick={() => descartar(clave)} aria-label="Descartar aviso">
            ×
          </button>
        </div>
      ))}
    </div>
  )
}
