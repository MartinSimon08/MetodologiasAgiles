import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { EnlaceEntidad } from '../../components/EnlaceEntidad'
import { etiquetaVehiculo } from '../../lib/vehiculo'
import { FilaEnlace } from '../../components/FilaEnlace'
import { Tabla } from '../../components/Tabla'
import { errorMessage } from '../../lib/api'
import { fechaHora } from '../../lib/formato'
import { obtenerCliente } from './api'
import { EditarClienteForm } from './EditarClienteForm'

export function ClienteDetallePage() {
  const clienteId = Number(useParams().id)
  const cliente = useQuery({ queryKey: ['cliente', clienteId], queryFn: () => obtenerCliente(clienteId) })
  const datos = cliente.data
  const [editando, setEditando] = useState(false)

  return (
    <section className="detalle-entidad">
      <Link to="/clientes" className="volver">
        ← Volver a clientes
      </Link>

      {cliente.isPending && <Cargando />}
      {cliente.isError && (
        <p className="error" role="alert">
          {errorMessage(cliente.error, 'No se pudo cargar el cliente.')}
        </p>
      )}

      {datos && (
        <>
          <header className="encabezado">
            <div>
              <h1>{datos.nombre}</h1>
              <p className="estado">
                <a href={`tel:${datos.telefono}`}>{datos.telefono}</a>
                {datos.email ? ` · ${datos.email}` : ''}
                {datos.telegram_vinculada ? ' · Telegram vinculado' : ' · Telegram sin vincular'}
              </p>
            </div>
            <span className="acciones">
              <span className={`insignia ${datos.asegurado ? 'insignia-asegurado' : 'insignia-desactivado'}`}>
                {datos.asegurado ? 'Asegurado' : 'Particular'}
              </span>
              <button type="button" className="secundario" onClick={() => setEditando(true)}>
                Editar
              </button>
            </span>
          </header>

          {editando && <EditarClienteForm cliente={datos} onTerminar={() => setEditando(false)} />}

          <section className="tarjeta">
            <h2>Vehículos</h2>
            {datos.vehiculos.length === 0 ? (
              <p className="estado">Todavía no tiene vehículos.</p>
            ) : (
              <Tabla etiqueta="Vehículos del cliente">
                <tbody>
                  {datos.vehiculos.map((vehiculo) => (
                    <FilaEnlace key={vehiculo.id} a={`/vehiculos/${vehiculo.id}/historial`}>
                      <td>
                        <EnlaceEntidad a={`/vehiculos/${vehiculo.id}/historial`}>{etiquetaVehiculo(vehiculo)}</EnlaceEntidad>
                      </td>
                      <td>{vehiculo.anio ?? <span className="sin-dato">—</span>}</td>
                    </FilaEnlace>
                  ))}
                </tbody>
              </Tabla>
            )}
          </section>

          {datos.casos.length > 0 && (
            <section className="tarjeta">
              <h2>Casos de aseguradora</h2>
              <Tabla etiqueta="Casos del cliente">
                <tbody>
                  {datos.casos.map((caso) => (
                    <FilaEnlace key={caso.id} a={`/casos/${caso.id}`}>
                      <td>
                        <EnlaceEntidad a={`/casos/${caso.id}`}>{caso.numero_siniestro}</EnlaceEntidad>
                      </td>
                      <td>
                        <EnlaceEntidad a={`/aseguradoras/${caso.aseguradora.id}`}>{caso.aseguradora.nombre}</EnlaceEntidad>
                      </td>
                      <td>{etiquetaVehiculo(caso.vehiculo)}</td>
                    </FilaEnlace>
                  ))}
                </tbody>
              </Tabla>
            </section>
          )}

          <section className="tarjeta">
            <h2>Órdenes</h2>
            {datos.ordenes.length === 0 ? (
              <p className="estado">Todavía no tiene órdenes.</p>
            ) : (
              <Tabla etiqueta="Órdenes del cliente">
                <tbody>
                  {datos.ordenes.map((orden) => (
                    <FilaEnlace key={orden.id} a={`/ordenes/${orden.id}`}>
                      <td>
                        <EnlaceEntidad a={`/ordenes/${orden.id}`}>Orden #{orden.id}</EnlaceEntidad>
                      </td>
                      <td>{etiquetaVehiculo(orden.vehiculo)}</td>
                      <td>
                        <span className={`insignia insignia-${orden.estado}`}>{orden.estado}</span>
                      </td>
                      <td className="fecha">{fechaHora(orden.created_at)}</td>
                    </FilaEnlace>
                  ))}
                </tbody>
              </Tabla>
            )}
          </section>
        </>
      )}
    </section>
  )
}
