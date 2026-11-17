import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { BotonNuevo } from '../../components/BotonNuevo'
import { Buscador } from '../../components/Buscador'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { fechaHora } from '../../lib/formato'
import { useDebounce } from '../../lib/useDebounce'
import { useAuth } from '../auth/AuthContext'
import { listarOrdenes } from './api'
import { NuevaOrdenForm } from './NuevaOrdenForm'
import { describirVehiculo, ESTADO_ORDEN_LABELS, type EstadoOrden } from './types'
import { Cargando } from '../../components/Cargando'
import { EstadoVacio } from '../../components/EstadoVacio'
import { Tabla } from '../../components/Tabla'

const ESTADOS = Object.keys(ESTADO_ORDEN_LABELS) as EstadoOrden[]

export function OrdenesPage() {
  const { usuario } = useAuth()
  const navigate = useNavigate()
  const [abriendo, setAbriendo] = useState(false)
  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)
  const estado = ESTADOS.find((valor) => valor === searchParams.get('estado'))
  const busqueda = searchParams.get('q') ?? ''
  const q = useDebounce(busqueda.trim())

  const ordenes = useQuery({
    queryKey: ['ordenes', pagina, estado ?? 'todas', q],
    queryFn: () => listarOrdenes(pagina, estado, q),
    placeholderData: keepPreviousData,
  })

  function navegar(nuevaPagina: number, nuevoEstado: EstadoOrden | undefined, nuevaBusqueda: string) {
    setSearchParams(
      {
        ...(nuevaBusqueda ? { q: nuevaBusqueda } : {}),
        ...(nuevoEstado ? { estado: nuevoEstado } : {}),
        ...(nuevaPagina === 1 ? {} : { pagina: String(nuevaPagina) }),
      },
      { replace: true },
    )
  }

  function irAPagina(nueva: number) {
    navegar(nueva, estado, busqueda)
    window.scrollTo({ top: 0 })
  }

  return (
    <section className="ordenes">
      <EncabezadoPagina titulo="Órdenes" bajada="Vehículos ingresados al taller y su estado.">
        {usuario?.rol === 'administrador' && !abriendo && (
          <BotonNuevo onClick={() => setAbriendo(true)}>Nueva orden</BotonNuevo>
        )}
      </EncabezadoPagina>

      {abriendo && (
        <NuevaOrdenForm
          onAbierta={(orden) => navigate(`/ordenes/${orden.id}`)}
          onCancelar={() => setAbriendo(false)}
        />
      )}

      <div className="filtros-ordenes">
        <Buscador
          etiqueta="Buscar orden"
          placeholder="Cliente, teléfono, patente, marca o modelo"
          valor={busqueda}
          onCambiar={(valor) => navegar(1, estado, valor)}
        />
        <label className="filtro-estado">
          <span>Estado</span>
          <select
            value={estado ?? ''}
            onChange={(e) =>
              navegar(
                1,
                ESTADOS.find((valor) => valor === e.target.value),
                busqueda,
              )
            }
          >
            <option value="">Todas</option>
            {ESTADOS.map((valor) => (
              <option key={valor} value={valor}>
                {ESTADO_ORDEN_LABELS[valor]}
              </option>
            ))}
          </select>
        </label>
      </div>

      {ordenes.isPending && <Cargando />}
      {ordenes.isError && (
        <p className="error" role="alert">
          {errorMessage(ordenes.error, 'No se pudieron cargar las órdenes.')}
        </p>
      )}

      {ordenes.data && ordenes.data.ordenes.length === 0 &&
        (q || estado ? (
          <EstadoVacio
            busqueda
            titulo="Sin resultados"
            descripcion={[
              'No hay órdenes',
              q && `que coincidan con “${q}”`,
              estado && `en estado ${ESTADO_ORDEN_LABELS[estado].toLowerCase()}`,
            ]
              .filter(Boolean)
              .join(' ')
              .concat('.')}
          />
        ) : (
          <EstadoVacio
            titulo="Todavía no hay órdenes"
            descripcion="Cuando ingrese un vehículo al taller, abrí una orden para cargarle tareas y repuestos."
          />
        ))}

      {ordenes.data && ordenes.data.ordenes.length > 0 && (
        <Tabla etiqueta="Órdenes" ocupada={ordenes.isPlaceholderData}>
          <thead>
            <tr>
              <th scope="col">Cliente</th>
              <th scope="col">Vehículo</th>
              <th scope="col">Ingreso</th>
              <th scope="col">Estado</th>
            </tr>
          </thead>
          <tbody>
            {ordenes.data.ordenes.map((orden) => (
              <tr key={orden.id}>
                <td>
                  <Link to={`/ordenes/${orden.id}`} className="enlace-fila">
                    {orden.cliente.nombre}
                  </Link>
                </td>
                <td>{describirVehiculo(orden.vehiculo)}</td>
                <td className="fecha">{fechaHora(orden.created_at)}</td>
                <td>
                  <span className={`insignia insignia-${orden.estado}`}>{ESTADO_ORDEN_LABELS[orden.estado]}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </Tabla>
      )}

      {ordenes.data && (
        <Paginacion meta={ordenes.data.meta} cargando={ordenes.isPlaceholderData} onCambiar={irAPagina} />
      )}
    </section>
  )
}
