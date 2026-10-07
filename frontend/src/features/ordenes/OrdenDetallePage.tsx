import { useQuery } from '@tanstack/react-query'
import { Link, useParams } from 'react-router-dom'
import { errorMessage } from '../../lib/api'
import { fechaHora } from '../../lib/formato'
import { AdelantosPanel } from '../adelantos/AdelantosPanel'
import { RepuestosPanel } from '../repuestos/RepuestosPanel'
import { TareasPanel } from '../tareas/TareasPanel'
import { obtenerOrden } from './api'
import { CancelarOrden } from './CancelarOrden'
import { describirVehiculo, ESTADO_ORDEN_LABELS } from './types'

export function OrdenDetallePage() {
  const { id } = useParams()
  const ordenId = Number(id)

  const orden = useQuery({
    queryKey: ['orden', ordenId],
    queryFn: () => obtenerOrden(ordenId),
  })

  return (
    <section className="orden-detalle">
      <Link to="/ordenes" className="volver">
        ← Volver a órdenes
      </Link>

      {orden.isPending && <p className="estado">Cargando orden…</p>}
      {orden.isError && (
        <p className="error" role="alert">
          {errorMessage(orden.error, 'No se pudo cargar la orden.')}
        </p>
      )}

      {orden.data && (
        <>
          <header className="encabezado">
            <div>
              <h1>{orden.data.cliente.nombre}</h1>
              <p className="estado">{describirVehiculo(orden.data.vehiculo)}</p>
              <p className="estado">Ingreso: {fechaHora(orden.data.created_at)}</p>
            </div>
            <span className={`insignia insignia-${orden.data.estado}`}>
              {ESTADO_ORDEN_LABELS[orden.data.estado]}
            </span>
          </header>

          <CancelarOrden orden={orden.data} />

          <section className="tarjeta motivo-orden">
            <h2>Motivo de ingreso</h2>
            <p>{orden.data.motivo}</p>
          </section>

          <TareasPanel ordenId={ordenId} ordenAbierta={orden.data.estado === 'abierta'} />
          <RepuestosPanel key={ordenId} ordenId={ordenId} ordenAbierta={orden.data.estado === 'abierta'} />
          <AdelantosPanel ordenId={ordenId} ordenAbierta={orden.data.estado === 'abierta'} />
        </>
      )}
    </section>
  )
}
