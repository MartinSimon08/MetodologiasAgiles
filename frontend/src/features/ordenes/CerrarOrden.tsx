import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { errorMessage, fieldErrors } from '../../lib/api'
import { fechaHora, importe } from '../../lib/formato'
import { useAuth } from '../auth/AuthContext'
import { cerrarOrden, obtenerResumenCierre } from './api'
import type { Orden, ResumenCierre } from './types'

interface Props {
  orden: Orden
}

function plural(cantidad: number, singular: string, varias: string) {
  return cantidad === 1 ? `1 ${singular}` : `${cantidad} ${varias}`
}

function Resumen({ resumen }: { resumen: ResumenCierre }) {
  const terminadas = resumen.tareas.filter((tarea) => tarea.estado === 'terminada')
  const valorizados = resumen.repuestos.filter((repuesto) => repuesto.estado === 'valorizado')

  return (
    <>
      <section className="bloque-cierre">
        <h3>Tareas terminadas</h3>
        {terminadas.length === 0 && <p className="estado">No hay tareas terminadas.</p>}
        <ul className="lineas-cierre">
          {terminadas.map((tarea) => (
            <li key={tarea.id} className={tarea.aprobacion === 'rechazada' ? 'linea-rechazada' : undefined}>
              <span>
                {tarea.descripcion}
                <small>
                  {tarea.mecanico ? `Hecha por ${tarea.mecanico.nombre}` : 'Sin responsable'}
                  {tarea.aprobacion === 'rechazada' ? ' · Rechazada, no suma' : ''}
                </small>
              </span>
              <span className={tarea.aprobacion === 'rechazada' ? 'sin-importe' : undefined}>
                {tarea.aprobacion === 'rechazada'
                  ? `No suma${tarea.precio != null ? ` · $ ${importe(tarea.precio)}` : ''}`
                  : tarea.precio != null
                    ? `$ ${importe(tarea.precio)}`
                    : 'Sin precio'}
              </span>
            </li>
          ))}
        </ul>
      </section>

      <section className="bloque-cierre">
        <h3>Repuestos</h3>
        {valorizados.length === 0 && <p className="estado">No hay repuestos cargados.</p>}
        <ul className="lineas-cierre">
          {valorizados.map((repuesto) => (
            <li key={repuesto.id} className={repuesto.aprobacion === 'rechazado' ? 'linea-rechazada' : undefined}>
              <span>
                {repuesto.descripcion}
                <small>
                  Cantidad: {repuesto.cantidad}
                  {repuesto.aprobacion === 'rechazado' ? ' · Rechazado, no suma' : ''}
                </small>
              </span>
              <span className={repuesto.aprobacion === 'rechazado' ? 'sin-importe' : undefined}>
                {repuesto.aprobacion === 'rechazado'
                  ? `No suma · $ ${importe(repuesto.precio_cliente ?? 0)}`
                  : `$ ${importe(repuesto.precio_cliente ?? 0)}`}
              </span>
            </li>
          ))}
        </ul>
      </section>

      <dl className="totales-cierre">
        <div>
          <dt>Mano de obra</dt>
          <dd>$ {importe(resumen.mano_de_obra)}</dd>
        </div>
        <div>
          <dt>Repuestos</dt>
          <dd>$ {importe(resumen.total_repuestos)}</dd>
        </div>
        <div className="total">
          <dt>Total</dt>
          <dd>$ {importe(resumen.total)}</dd>
        </div>
        {Number(resumen.adelantado) > 0 && (
          <>
            <div>
              <dt>Adelantado</dt>
              <dd>$ {importe(resumen.adelantado)}</dd>
            </div>
            <div>
              <dt>Saldo a cobrar</dt>
              <dd>$ {importe(resumen.saldo)}</dd>
            </div>
          </>
        )}
      </dl>
    </>
  )
}

function OrdenCerrada({ orden, esAdministrador }: { orden: Orden; esAdministrador: boolean }) {
  const resumen = useQuery({
    queryKey: ['resumen-cierre', orden.id],
    queryFn: () => obtenerResumenCierre(orden.id),
    enabled: esAdministrador,
  })

  return (
    <div className="tarjeta orden-cerrada" role="status">
      <strong>
        Orden cerrada
        {orden.cerrada_en && ` el ${fechaHora(orden.cerrada_en)}`}
        {orden.cerrada_por && ` por ${orden.cerrada_por.nombre}`}
      </strong>
      <span>El total quedó congelado. Las tareas y los repuestos son de solo lectura.</span>
      {esAdministrador && resumen.data && <Resumen resumen={resumen.data} />}
    </div>
  )
}

export function CerrarOrden({ orden }: Props) {
  const { usuario } = useAuth()
  const queryClient = useQueryClient()
  const esAdministrador = usuario?.rol === 'administrador'
  const [revisando, setRevisando] = useState(false)
  const [descartar, setDescartar] = useState(false)

  const resumen = useQuery({
    queryKey: ['resumen-cierre', orden.id],
    queryFn: () => obtenerResumenCierre(orden.id),
    enabled: revisando && esAdministrador,
    staleTime: 0,
  })

  const mutation = useMutation({
    mutationFn: () => cerrarOrden(orden.id, descartar),
    onSuccess: () => {
      setRevisando(false)
      queryClient.invalidateQueries({ queryKey: ['orden', orden.id] })
      queryClient.invalidateQueries({ queryKey: ['ordenes'] })
      queryClient.invalidateQueries({ queryKey: ['tareas', orden.id] })
      queryClient.invalidateQueries({ queryKey: ['repuestos', orden.id] })
      queryClient.invalidateQueries({ queryKey: ['adelantos', orden.id] })
      queryClient.invalidateQueries({ queryKey: ['resumen-cierre', orden.id] })
    },
    onError: () => resumen.refetch(),
  })

  if (orden.estado === 'cerrada') return <OrdenCerrada orden={orden} esAdministrador={esAdministrador} />
  if (orden.estado !== 'abierta' || !esAdministrador) return null

  if (!revisando) {
    return (
      <div className="acciones">
        <button
          type="button"
          onClick={() => {
            mutation.reset()
            setDescartar(false)
            setRevisando(true)
          }}
        >
          Cerrar orden
        </button>
      </div>
    )
  }

  const datos = resumen.data
  const enCurso = datos?.tareas.filter((tarea) => tarea.estado === 'en_curso') ?? []
  const pendientes = datos?.tareas.filter((tarea) => tarea.estado === 'pendiente') ?? []
  const sinValorizar = datos?.repuestos.filter((repuesto) => repuesto.estado === 'pendiente_de_valorizar') ?? []
  const bloqueada = enCurso.length > 0 || sinValorizar.length > 0
  const puedeCerrar = datos != null && !bloqueada && (pendientes.length === 0 || descartar)
  const errores = fieldErrors(mutation.error).base

  return (
    <div className="tarjeta formulario cerrar-orden" role="group" aria-label="Cerrar la orden">
      <h2>Resumen del cierre</h2>

      {resumen.isPending && <p className="estado">Calculando el total…</p>}
      {resumen.isError && (
        <p className="error" role="alert">
          {errorMessage(resumen.error, 'No se pudo calcular el resumen de la orden.')}
        </p>
      )}

      {datos && (
        <>
          <Resumen resumen={datos} />

          {enCurso.length > 0 && (
            <div className="bloqueo-cierre" role="alert">
              <strong>No se puede cerrar: hay {plural(enCurso.length, 'tarea tomada', 'tareas tomadas')}.</strong>
              <ul>
                {enCurso.map((tarea) => (
                  <li key={tarea.id}>
                    {tarea.descripcion}
                    {tarea.mecanico && ` (${tarea.mecanico.nombre})`}
                  </li>
                ))}
              </ul>
              <span>El mecánico tiene que terminarlas o liberarlas antes del cierre.</span>
            </div>
          )}

          {sinValorizar.length > 0 && (
            <div className="bloqueo-cierre" role="alert">
              <strong>
                No se puede cerrar: hay{' '}
                {plural(sinValorizar.length, 'repuesto pendiente', 'repuestos pendientes')} de valorizar.
              </strong>
              <ul>
                {sinValorizar.map((repuesto) => (
                  <li key={repuesto.id}>{repuesto.descripcion}</li>
                ))}
              </ul>
            </div>
          )}

          {pendientes.length > 0 && (
            <label className="descartar-pendientes">
              <span>
                <input type="checkbox" checked={descartar} onChange={(e) => setDescartar(e.target.checked)} />
                Descartar {plural(pendientes.length, 'tarea pendiente', 'tareas pendientes')} sin tomar
              </span>
              <small>{pendientes.map((tarea) => tarea.descripcion).join(', ')}. No se cobran y quedan canceladas.</small>
            </label>
          )}

          <p className="advertencia">
            Al cerrar, el total queda congelado y la orden pasa a ser de solo lectura. No se puede deshacer.
          </p>
        </>
      )}

      {mutation.isError && (
        <p className="error" role="alert">
          {errores?.join('. ') ?? errorMessage(mutation.error, 'No se pudo cerrar la orden.')}
        </p>
      )}

      <div className="acciones">
        <button type="button" className="secundario" onClick={() => setRevisando(false)}>
          Volver
        </button>
        <button type="button" disabled={!puedeCerrar || mutation.isPending} onClick={() => mutation.mutate()}>
          {mutation.isPending ? 'Cerrando…' : `Confirmar cierre${datos ? ` por $ ${importe(datos.total)}` : ''}`}
        </button>
      </div>
    </div>
  )
}
