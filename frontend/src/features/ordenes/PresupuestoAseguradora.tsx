import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { errorMessage } from '../../lib/api'
import { importe } from '../../lib/formato'
import { aprobarRepuesto, APROBACION_REPUESTO_LABELS, rechazarRepuesto } from '../repuestos/api'
import { aprobarTarea, rechazarTarea } from '../tareas/api'
import { APROBACION_TAREA_LABELS, ESTADO_TAREA_LABELS } from '../tareas/types'
import { obtenerPresupuesto } from './api'
import { invalidarTotalesOrden } from './totales'
import type { Presupuesto } from './types'

function responsable(tarea: Presupuesto['tareas'][number]) {
  if (tarea.mecanico === null) return 'Sin tomar'
  return tarea.estado === 'terminada' ? `Hecha por ${tarea.mecanico.nombre}` : tarea.mecanico.nombre
}

export function PresupuestoAseguradora({ ordenId }: { ordenId: number }) {
  const queryClient = useQueryClient()
  const consulta = useQuery({
    queryKey: ['presupuesto', ordenId],
    queryFn: () => obtenerPresupuesto(ordenId),
  })
  const decidir = useMutation({
    mutationFn: async (accion: { tipo: 'tarea' | 'repuesto'; id: number; decision: 'aprobar' | 'rechazar' }) => {
      if (accion.tipo === 'tarea') {
        await (accion.decision === 'aprobar' ? aprobarTarea(accion.id) : rechazarTarea(accion.id))
        return
      }
      await (accion.decision === 'aprobar' ? aprobarRepuesto(ordenId, accion.id) : rechazarRepuesto(ordenId, accion.id))
    },
    onSuccess: () => {
      invalidarTotalesOrden(queryClient, ordenId)
      queryClient.invalidateQueries({ queryKey: ['tareas', ordenId] })
      queryClient.invalidateQueries({ queryKey: ['repuestos', ordenId] })
    },
  })
  const datos = consulta.data

  function marcar(tipo: 'tarea' | 'repuesto', id: number, decision: 'aprobar' | 'rechazar') {
    decidir.mutate({ tipo, id, decision })
  }

  return (
    <section className="tarjeta total-parcial" aria-labelledby="presupuesto-titulo" aria-busy={consulta.isFetching}>
      <header className="encabezado">
        <div>
          <h2 id="presupuesto-titulo">Presupuesto para la aseguradora</h2>
          <p className="bajada">
            Lo cargado hasta ahora. Si el cliente rechaza un ítem, queda en el detalle y no entra en el total.
          </p>
        </div>
        {datos && <strong className="total-parcial-monto">$ {importe(datos.total_aseguradora)}</strong>}
      </header>

      {consulta.isPending && <p className="estado">Calculando el presupuesto…</p>}
      {consulta.isError && (
        <p className="error" role="alert">
          {errorMessage(consulta.error, 'No se pudo calcular el presupuesto.')}
        </p>
      )}
      {decidir.isError && (
        <p className="error" role="alert">
          {errorMessage(decidir.error, 'No se pudo registrar la decisión.')}
        </p>
      )}

      {datos && (
        <>
          <section className="bloque-cierre">
            <h3>Mano de obra</h3>
            {datos.tareas.length === 0 && <p className="estado">Todavía no hay tareas cargadas.</p>}
            <ul className="lineas-cierre">
              {datos.tareas.map((tarea) => {
                const rechazada = tarea.aprobacion === 'rechazada'
                return (
                  <li key={tarea.id} className={rechazada ? 'linea-rechazada' : undefined}>
                    <span>
                      {tarea.descripcion}
                      <small>
                        {ESTADO_TAREA_LABELS[tarea.estado]} · {responsable(tarea)} ·{' '}
                        {APROBACION_TAREA_LABELS[tarea.aprobacion]}
                      </small>
                      <span className="acciones">
                        <button
                          type="button"
                          className="secundario"
                          aria-pressed={tarea.aprobacion === 'aprobada'}
                          disabled={decidir.isPending || tarea.aprobacion === 'aprobada'}
                          onClick={() => marcar('tarea', tarea.id, 'aprobar')}
                        >
                          Aprobar
                        </button>
                        <button
                          type="button"
                          className="secundario"
                          aria-pressed={rechazada}
                          disabled={decidir.isPending || rechazada}
                          onClick={() => marcar('tarea', tarea.id, 'rechazar')}
                        >
                          Rechazar
                        </button>
                      </span>
                    </span>
                    {tarea.precio == null ? (
                      <span className="sin-importe">Sin precio</span>
                    ) : rechazada ? (
                      <span className="sin-importe">No suma · $ {importe(tarea.precio)}</span>
                    ) : (
                      <span>$ {importe(tarea.precio)}</span>
                    )}
                  </li>
                )
              })}
            </ul>
          </section>

          <section className="bloque-cierre">
            <h3>Repuestos</h3>
            {datos.repuestos.length === 0 && <p className="estado">Todavía no hay repuestos cargados.</p>}
            <ul className="lineas-cierre">
              {datos.repuestos.map((repuesto) => {
                const rechazado = repuesto.aprobacion === 'rechazado'
                return (
                  <li key={repuesto.id} className={rechazado ? 'linea-rechazada' : undefined}>
                    <span>
                      {repuesto.descripcion}
                      <small>
                        Cantidad: {repuesto.cantidad} · {APROBACION_REPUESTO_LABELS[repuesto.aprobacion]}
                        {repuesto.estado === 'pendiente_de_valorizar' ? ' · Falta cargar el costo' : ''}
                      </small>
                      <span className="acciones">
                        <button
                          type="button"
                          className="secundario"
                          aria-pressed={repuesto.aprobacion === 'aprobado'}
                          disabled={decidir.isPending || repuesto.aprobacion === 'aprobado'}
                          onClick={() => marcar('repuesto', repuesto.id, 'aprobar')}
                        >
                          Aprobar
                        </button>
                        <button
                          type="button"
                          className="secundario"
                          aria-pressed={rechazado}
                          disabled={decidir.isPending || rechazado}
                          onClick={() => marcar('repuesto', repuesto.id, 'rechazar')}
                        >
                          Rechazar
                        </button>
                      </span>
                    </span>
                    {repuesto.precio_cliente == null ? (
                      <span className="sin-importe">Sin precio</span>
                    ) : rechazado ? (
                      <span className="sin-importe">No suma · $ {importe(repuesto.precio_cliente)}</span>
                    ) : (
                      <span>$ {importe(repuesto.precio_cliente)}</span>
                    )}
                  </li>
                )
              })}
            </ul>
          </section>

          <dl className="totales-cierre">
            <div>
              <dt>Presupuesto estimado</dt>
              <dd>$ {importe(datos.presupuesto)}</dd>
            </div>
            <div className="total">
              <dt>Total para la aseguradora</dt>
              <dd>$ {importe(datos.total_aseguradora)}</dd>
            </div>
          </dl>
          {datos.presupuesto !== datos.total_aseguradora && (
            <p className="estado">
              El presupuesto incluye lo rechazado. El total para la aseguradora no.
            </p>
          )}
        </>
      )}
    </section>
  )
}
