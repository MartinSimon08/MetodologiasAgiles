import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { fechaHora } from '../../lib/formato'
import { useAuth } from '../auth/AuthContext'
import { listarOrdenes } from './api'
import { NuevaOrdenForm } from './NuevaOrdenForm'
import { describirVehiculo, ESTADO_ORDEN_LABELS } from './types'

export function OrdenesPage() {
  const { usuario } = useAuth()
  const navigate = useNavigate()
  const [abriendo, setAbriendo] = useState(false)
  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)

  const ordenes = useQuery({
    queryKey: ['ordenes', pagina],
    queryFn: () => listarOrdenes(pagina),
    placeholderData: keepPreviousData,
  })

  function irAPagina(nueva: number) {
    setSearchParams(nueva === 1 ? {} : { pagina: String(nueva) })
    window.scrollTo({ top: 0 })
  }

  return (
    <section className="ordenes">
      <header className="encabezado">
        <h1>Órdenes</h1>
        {usuario?.rol === 'administrador' && !abriendo && (
          <button onClick={() => setAbriendo(true)}>Nueva orden</button>
        )}
      </header>

      {abriendo && (
        <NuevaOrdenForm
          onAbierta={(orden) => navigate(`/ordenes/${orden.id}`)}
          onCancelar={() => setAbriendo(false)}
        />
      )}

      {ordenes.isPending && <p className="estado">Cargando órdenes…</p>}
      {ordenes.isError && (
        <p className="error" role="alert">
          {errorMessage(ordenes.error, 'No se pudieron cargar las órdenes.')}
        </p>
      )}

      {ordenes.data && ordenes.data.ordenes.length === 0 && (
        <p className="estado">Todavía no hay órdenes cargadas.</p>
      )}

      {ordenes.data && (
        <ul className="lista" aria-busy={ordenes.isPlaceholderData}>
          {ordenes.data.ordenes.map((orden) => (
            <li key={orden.id} className="tarjeta fila-item">
              <Link to={`/ordenes/${orden.id}`} className="item-datos">
                <strong>{orden.cliente.nombre}</strong>
                <span>{describirVehiculo(orden.vehiculo)}</span>
                <span>Ingreso: {fechaHora(orden.created_at)}</span>
              </Link>
              <span className={`insignia insignia-${orden.estado}`}>
                {ESTADO_ORDEN_LABELS[orden.estado]}
              </span>
            </li>
          ))}
        </ul>
      )}

      {ordenes.data && (
        <Paginacion meta={ordenes.data.meta} cargando={ordenes.isPlaceholderData} onCambiar={irAPagina} />
      )}
    </section>
  )
}
