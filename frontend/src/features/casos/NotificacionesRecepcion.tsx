import { useQueryClient } from '@tanstack/react-query'
import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { cable } from '../../lib/cable'
import { useAuth } from '../auth/AuthContext'
import { describirVehiculo } from '../ordenes/types'
import type { AvisoCasoListoParaRetirar } from './types'

const MAX_VISIBLES = 5

interface AvisoConClave {
  clave: number
  aviso: AvisoCasoListoParaRetirar
}

export function NotificacionesRecepcion() {
  const { usuario } = useAuth()
  const queryClient = useQueryClient()
  const [avisos, setAvisos] = useState<AvisoConClave[]>([])
  const proximaClave = useRef(0)

  useEffect(() => {
    if (usuario?.rol !== 'administrador') return

    const suscripcion = cable.subscriptions.create(
      { channel: 'RecepcionChannel' },
      {
        received(aviso: AvisoCasoListoParaRetirar) {
          queryClient.invalidateQueries({ queryKey: ['casos'] })
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
          <Link to="/casos" onClick={() => descartar(clave)}>
            <strong>Caso listo para retirar</strong>
            <span>
              Siniestro {aviso.numero_siniestro} · {aviso.aseguradora.nombre}
            </span>
            <span>{describirVehiculo(aviso.vehiculo)}</span>
          </Link>
          <button className="secundario" onClick={() => descartar(clave)} aria-label="Descartar aviso">
            ×
          </button>
        </div>
      ))}
    </div>
  )
}
