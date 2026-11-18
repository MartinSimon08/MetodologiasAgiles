import { useInfiniteQuery } from '@tanstack/react-query'
import { useState, type DragEvent } from 'react'
import { Link } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { Dialogo } from '../../components/Dialogo'
import { errorMessage } from '../../lib/api'
import { fechaHora } from '../../lib/formato'
import { useAuth } from '../auth/AuthContext'
import { listarOrdenes } from './api'
import { CancelarOrden } from './CancelarOrden'
import { CerrarOrden } from './CerrarOrden'
import { describirVehiculo, ESTADO_ORDEN_LABELS, type EstadoOrden, type Orden } from './types'

const ESTADOS = Object.keys(ESTADO_ORDEN_LABELS) as EstadoOrden[]
const DESTINOS_DESDE_ABIERTA: EstadoOrden[] = ['cerrada', 'cancelada']

interface Movimiento {
  orden: Orden
  destino: EstadoOrden
}

export function TableroOrdenes() {
  const { usuario } = useAuth()
  const puedeMover = usuario?.rol === 'administrador'
  const [arrastrada, setArrastrada] = useState<Orden | null>(null)
  const [movimiento, setMovimiento] = useState<Movimiento | null>(null)

  function aceptaDestino(estado: EstadoOrden) {
    return arrastrada?.estado === 'abierta' && DESTINOS_DESDE_ABIERTA.includes(estado)
  }

  function soltar(estado: EstadoOrden) {
    if (arrastrada && aceptaDestino(estado)) setMovimiento({ orden: arrastrada, destino: estado })
    setArrastrada(null)
  }

  const cerrarDialogo = () => setMovimiento(null)

  return (
    <>
      {puedeMover && (
        <p className="estado ayuda-tablero">Arrastrá una orden abierta a Cerrada o Cancelada para cerrarla o cancelarla.</p>
      )}

      <div className={`tablero-ordenes${arrastrada ? ' arrastrando' : ''}`}>
        {ESTADOS.map((estado) => (
          <ColumnaTablero
            key={estado}
            estado={estado}
            puedeMover={puedeMover}
            acepta={aceptaDestino(estado)}
            onArrastrar={setArrastrada}
            onSoltar={() => soltar(estado)}
            onFinArrastre={() => setArrastrada(null)}
          />
        ))}
      </div>

      {movimiento && (
        <Dialogo onCerrar={cerrarDialogo}>
          {movimiento.destino === 'cerrada' ? (
            <CerrarOrden orden={movimiento.orden} iniciarRevision onTerminar={cerrarDialogo} />
          ) : (
            <CancelarOrden orden={movimiento.orden} iniciarConfirmacion onTerminar={cerrarDialogo} />
          )}
        </Dialogo>
      )}
    </>
  )
}

interface ColumnaProps {
  estado: EstadoOrden
  puedeMover: boolean
  acepta: boolean
  onArrastrar: (orden: Orden) => void
  onSoltar: () => void
  onFinArrastre: () => void
}

function ColumnaTablero({ estado, puedeMover, acepta, onArrastrar, onSoltar, onFinArrastre }: ColumnaProps) {
  const [encima, setEncima] = useState(false)
  const ordenes = useInfiniteQuery({
    queryKey: ['ordenes', 'tablero', estado],
    queryFn: ({ pageParam }) => listarOrdenes(pageParam, estado),
    initialPageParam: 1,
    getNextPageParam: ({ meta }) => (meta.pagina < meta.total_paginas ? meta.pagina + 1 : undefined),
  })

  const items = ordenes.data?.pages.flatMap((pagina) => pagina.ordenes) ?? []
  const total = ordenes.data?.pages[0]?.meta.total
  const titulo = `columna-${estado}`
  const arrastrable = puedeMover && estado === 'abierta'

  function alPasar(event: DragEvent) {
    if (!acepta) return
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
    setEncima(true)
  }

  function alSoltar(event: DragEvent) {
    event.preventDefault()
    setEncima(false)
    onSoltar()
  }

  const clases = ['columna-tablero', `columna-tablero-${estado}`]
  if (acepta) clases.push('columna-tablero-destino')
  if (acepta && encima) clases.push('columna-tablero-encima')

  return (
    <section
      className={clases.join(' ')}
      aria-labelledby={titulo}
      onDragOver={alPasar}
      onDragLeave={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget as Node | null)) setEncima(false)
      }}
      onDrop={alSoltar}
    >
      <header className="columna-tablero-encabezado">
        <h2 id={titulo}>
          <span className={`insignia insignia-${estado}`}>{ESTADO_ORDEN_LABELS[estado]}</span>
        </h2>
        {total !== undefined && <span className="columna-tablero-total">{total}</span>}
      </header>

      {ordenes.isPending && <Cargando />}
      {ordenes.isError && (
        <p className="error" role="alert">
          {errorMessage(ordenes.error, 'No se pudieron cargar las órdenes.')}
        </p>
      )}

      {ordenes.isSuccess && items.length === 0 && <p className="estado">Sin órdenes.</p>}

      {items.length > 0 && (
        <ul className="lista">
          {items.map((orden) => (
            <li key={orden.id} className="tarjeta tarjeta-enlazada">
              <Link
                to={`/ordenes/${orden.id}`}
                className={`enlace-tarjeta item-datos tarjeta-tablero${arrastrable ? ' arrastrable' : ''}`}
                draggable={arrastrable}
                onDragStart={(event) => {
                  if (!arrastrable) return
                  event.dataTransfer.effectAllowed = 'move'
                  event.dataTransfer.setData('text/plain', String(orden.id))
                  onArrastrar(orden)
                }}
                onDragEnd={onFinArrastre}
              >
                <strong>{orden.cliente.nombre}</strong>
                <span>{describirVehiculo(orden.vehiculo)}</span>
                <span>Ingreso: {fechaHora(orden.created_at)}</span>
              </Link>
            </li>
          ))}
        </ul>
      )}

      {ordenes.hasNextPage && (
        <button
          type="button"
          className="secundario"
          disabled={ordenes.isFetchingNextPage}
          onClick={() => ordenes.fetchNextPage()}
        >
          {ordenes.isFetchingNextPage ? 'Cargando…' : 'Ver más'}
        </button>
      )}
    </section>
  )
}
