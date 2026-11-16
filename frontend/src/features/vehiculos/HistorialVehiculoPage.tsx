import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { Link, useParams, useSearchParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { fechaHora, importe } from '../../lib/formato'
import { describirVehiculo } from '../ordenes/types'
import { obtenerHistorialVehiculo, type OrdenHistorial } from './api'

function OrdenDelHistorial({ orden }: { orden: OrdenHistorial }) {
  return (
    <li className="tarjeta orden-historial">
      <header className="orden-historial-encabezado">
        <div>
          <h2>
            <Link to={`/ordenes/${orden.id}`}>Orden #{orden.id}</Link>
          </h2>
          <p className="estado">
            Cerrada el {fechaHora(orden.cerrada_en)} por {orden.cerrada_por.nombre}
          </p>
          <p className="estado">Cliente: {orden.cliente.nombre}</p>
        </div>
      </header>

      <section className="bloque-cierre">
        <h3>Motivo de ingreso</h3>
        <p className="motivo-historial">{orden.motivo}</p>
      </section>

      <section className="bloque-cierre">
        <h3>Mecánicos</h3>
        <p className="motivo-historial">
          {orden.mecanicos.length > 0
            ? orden.mecanicos.map((mecanico) => mecanico.nombre).join(', ')
            : 'Sin mecánicos registrados'}
        </p>
      </section>

      <section className="bloque-cierre">
        <h3>Tareas</h3>
        {orden.tareas.length === 0 && <p className="estado">No hay tareas cobradas.</p>}
        <ul className="lineas-cierre">
          {orden.tareas.map((tarea) => (
            <li key={tarea.id}>
              <span>
                {tarea.descripcion}
                <small>{tarea.mecanico ? `Hecha por ${tarea.mecanico.nombre}` : 'Sin responsable'}</small>
              </span>
              <span>{tarea.precio != null ? `$ ${importe(tarea.precio)}` : 'Sin precio'}</span>
            </li>
          ))}
        </ul>
      </section>

      <section className="bloque-cierre">
        <h3>Repuestos</h3>
        {orden.repuestos.length === 0 && <p className="estado">No hay repuestos cobrados.</p>}
        <ul className="lineas-cierre">
          {orden.repuestos.map((repuesto) => (
            <li key={repuesto.id}>
              <span>
                {repuesto.descripcion}
                <small>Cantidad: {repuesto.cantidad}</small>
              </span>
              <span>$ {importe(repuesto.precio_cliente ?? 0)}</span>
            </li>
          ))}
        </ul>
      </section>

      <dl className="totales-cierre">
        <div className="total">
          <dt>Total cobrado</dt>
          <dd>$ {importe(orden.total)}</dd>
        </div>
      </dl>
    </li>
  )
}

export function HistorialVehiculoPage() {
  const { id } = useParams()
  const vehiculoId = Number(id)
  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)

  const historial = useQuery({
    queryKey: ['historial-vehiculo', vehiculoId, pagina],
    queryFn: () => obtenerHistorialVehiculo(vehiculoId, pagina),
    placeholderData: keepPreviousData,
  })

  function irAPagina(nueva: number) {
    setSearchParams(nueva > 1 ? { pagina: String(nueva) } : {}, { replace: true })
    window.scrollTo({ top: 0 })
  }

  return (
    <section className="historial-vehiculo">
      <Link to="/vehiculos" className="volver">
        ← Volver a vehículos
      </Link>

      {historial.isPending && <Cargando />}
      {historial.isError && (
        <p className="error" role="alert">
          {errorMessage(historial.error, 'No se pudo cargar el historial del vehículo.')}
        </p>
      )}

      {historial.data && (
        <>
          <header className="encabezado">
            <div>
              <h1>Historial</h1>
              <p className="bajada">{describirVehiculo(historial.data.vehiculo)}</p>
              <p className="estado">Dueño actual: {historial.data.vehiculo.cliente.nombre}</p>
            </div>
          </header>

          {historial.data.ordenes.length === 0 && (
            <p className="estado">Este vehículo todavía no tiene órdenes cerradas.</p>
          )}

          {historial.data.ordenes.length > 0 && (
            <ul className="historial-ordenes" aria-busy={historial.isPlaceholderData}>
              {historial.data.ordenes.map((orden) => (
                <OrdenDelHistorial key={orden.id} orden={orden} />
              ))}
            </ul>
          )}

          <Paginacion meta={historial.data.meta} cargando={historial.isPlaceholderData} onCambiar={irAPagina} />
        </>
      )}
    </section>
  )
}
