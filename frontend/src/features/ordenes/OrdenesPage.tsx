import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { Link, useSearchParams } from 'react-router-dom'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { listarOrdenes } from './api'
import { ESTADO_ORDEN_LABELS } from './types'

export function OrdenesPage() {
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
      </header>

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
                <span>{orden.vehiculo}</span>
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
