import { useQuery } from '@tanstack/react-query'
import { errorMessage } from '../../lib/api'
import { importe } from '../../lib/formato'
import { ESTADO_REPUESTO_LABELS } from '../repuestos/api'
import { ESTADO_TAREA_LABELS } from '../tareas/types'
import { obtenerTotalParcial } from './api'
import type { TotalParcial } from './types'

function responsable(tarea: TotalParcial['tareas'][number]) {
  if (tarea.mecanico === null) return 'Sin tomar'
  return tarea.estado === 'terminada' ? `Hecha por ${tarea.mecanico.nombre}` : tarea.mecanico.nombre
}

export function TotalParcialOrden({ ordenId }: { ordenId: number }) {
  const consulta = useQuery({
    queryKey: ['total-parcial', ordenId],
    queryFn: () => obtenerTotalParcial(ordenId),
  })
  const datos = consulta.data

  return (
    <section
      className="tarjeta total-parcial"
      aria-labelledby="total-parcial-titulo"
      aria-busy={consulta.isFetching}
    >
      <header className="encabezado">
        <div>
          <h2 id="total-parcial-titulo">Total parcial</h2>
          <p className="bajada">Lo que lleva la orden hasta ahora. Se actualiza al cargar tareas o repuestos.</p>
        </div>
        {datos && <strong className="total-parcial-monto">$ {importe(datos.total)}</strong>}
      </header>

      {consulta.isPending && <p className="estado">Calculando el total…</p>}
      {consulta.isError && (
        <p className="error" role="alert">
          {errorMessage(consulta.error, 'No se pudo calcular el total parcial.')}
        </p>
      )}

      {datos && (
        <>
          <section className="bloque-cierre">
            <h3>Mano de obra</h3>
            {datos.tareas.length === 0 && <p className="estado">Todavía no hay tareas cargadas.</p>}
            <ul className="lineas-cierre">
              {datos.tareas.map((tarea) => (
                <li key={tarea.id} className={tarea.aprobacion === 'rechazada' ? 'linea-rechazada' : undefined}>
                  <span>
                    {tarea.descripcion}
                    <small>
                      {ESTADO_TAREA_LABELS[tarea.estado]} · {responsable(tarea)}
                      {tarea.aprobacion === 'rechazada' ? ' · Rechazada, no suma' : ''}
                    </small>
                  </span>
                  {tarea.precio == null ? (
                    <span className="sin-importe">Sin precio</span>
                  ) : tarea.aprobacion === 'rechazada' ? (
                    <span className="sin-importe">No suma · $ {importe(tarea.precio)}</span>
                  ) : (
                    <span>$ {importe(tarea.precio)}</span>
                  )}
                </li>
              ))}
            </ul>
          </section>

          <section className="bloque-cierre">
            <h3>Repuestos</h3>
            {datos.repuestos.length === 0 && <p className="estado">Todavía no hay repuestos cargados.</p>}
            <ul className="lineas-cierre">
              {datos.repuestos.map((repuesto) => (
                <li key={repuesto.id} className={repuesto.aprobacion === 'rechazado' ? 'linea-rechazada' : undefined}>
                  <span>
                    {repuesto.descripcion}
                    {repuesto.estado === 'valorizado' ? (
                      <small>
                        {repuesto.cantidad} × $ {importe(repuesto.costo_unitario!)} de costo · Margen{' '}
                        {importe(repuesto.margen!)}%
                      </small>
                    ) : (
                      <small>Cantidad: {repuesto.cantidad} · Falta cargar el costo</small>
                    )}
                  </span>
                  {repuesto.aprobacion === 'rechazado' ? (
                    <span className="sin-importe">
                      No suma{repuesto.precio_cliente != null ? ` · $ ${importe(repuesto.precio_cliente)}` : ''}
                    </span>
                  ) : repuesto.estado === 'valorizado' ? (
                    <span>$ {importe(repuesto.precio_cliente!)}</span>
                  ) : (
                    <span className="insignia insignia-pendiente_de_valorizar">
                      {ESTADO_REPUESTO_LABELS[repuesto.estado]}
                    </span>
                  )}
                </li>
              ))}
            </ul>
          </section>

          <dl className="totales-cierre">
            <div>
              <dt>Mano de obra</dt>
              <dd>$ {importe(datos.mano_de_obra)}</dd>
            </div>
            <div>
              <dt>Repuestos (precio al cliente)</dt>
              <dd>$ {importe(datos.total_repuestos)}</dd>
            </div>
            <div className="total">
              <dt>Total parcial</dt>
              <dd>$ {importe(datos.total)}</dd>
            </div>
          </dl>

          {datos.a_cobrar_hoy !== datos.total && (
            <p className="estado">
              Si cerrás ahora se cobran $ {importe(datos.a_cobrar_hoy)}: solo cuentan las tareas terminadas.
            </p>
          )}
        </>
      )}
    </section>
  )
}
