import { useQuery } from '@tanstack/react-query'
import { Link, useParams } from 'react-router-dom'
import { errorMessage } from '../../lib/api'
import { useAuth } from '../auth/AuthContext'
import { RepuestosPanel } from '../repuestos/RepuestosPanel'
import { TareasPanel } from '../tareas/TareasPanel'
import { obtenerOrden } from './api'
import { ESTADO_ORDEN_LABELS } from './types'

export function OrdenDetallePage() {
  const { usuario } = useAuth()
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
              <p className="estado">{orden.data.vehiculo}</p>
            </div>
            <span className={`insignia insignia-${orden.data.estado}`}>
              {ESTADO_ORDEN_LABELS[orden.data.estado]}
            </span>
          </header>

          <TareasPanel ordenId={ordenId} ordenAbierta={orden.data.estado === 'abierta'} />
          {usuario?.rol === 'administrador' && (
            <RepuestosPanel key={ordenId} ordenId={ordenId} ordenAbierta={orden.data.estado === 'abierta'} />
          )}
        </>
      )}
    </section>
  )
}
