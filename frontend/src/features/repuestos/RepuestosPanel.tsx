import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage, fieldErrors } from '../../lib/api'
import { fechaHora, importe } from '../../lib/formato'
import { useAuth } from '../auth/AuthContext'
import { invalidarTotalesOrden } from '../ordenes/totales'
import { AvisoRepuestoForm } from './AvisoRepuestoForm'
import { ComprobanteRepuesto } from './ComprobanteRepuesto'
import { listarRepuestos, quitarRepuesto, ESTADO_REPUESTO_LABELS, type AjusteRepuesto, type Repuesto, type TipoAjuste } from './api'
import { EditarRepuestoForm } from './EditarRepuestoForm'
import { NuevoRepuestoForm } from './NuevoRepuestoForm'
import { RegistrarAjusteForm } from './RegistrarAjusteForm'
import { ValorizarRepuestoForm } from './ValorizarRepuestoForm'
import { Cargando } from '../../components/Cargando'

export function RepuestosPanel({ ordenId, ordenAbierta }: { ordenId: number; ordenAbierta: boolean }) {
  const { usuario } = useAuth()
  const esAdministrador = usuario?.rol === 'administrador'
  const queryClient = useQueryClient()
  const [creando, setCreando] = useState(false)
  const [pagina, setPagina] = useState(1)
  const [aviso, setAviso] = useState<string | null>(null)
  const [editando, setEditando] = useState<Repuesto | null>(null)
  const [valorizando, setValorizando] = useState<Repuesto | null>(null)
  const [quitandoId, setQuitandoId] = useState<number | null>(null)
  const [ajustando, setAjustando] = useState<Repuesto | null>(null)

  const repuestos = useQuery({
    queryKey: ['repuestos', ordenId, pagina],
    queryFn: () => listarRepuestos(ordenId, pagina),
  })
  const quitar = useMutation({
    mutationFn: (id: number) => quitarRepuesto(ordenId, id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['repuestos', ordenId] })
      invalidarTotalesOrden(queryClient, ordenId)
      setQuitandoId(null)
      setAviso('Repuesto quitado. La baja quedó registrada.')
    },
  })

  function empezarCarga() {
    quitar.reset()
    setEditando(null)
    setValorizando(null)
    setQuitandoId(null)
    setAjustando(null)
    setAviso(null)
    setCreando(true)
  }

  function empezarEdicion(repuesto: Repuesto) {
    quitar.reset()
    setCreando(false)
    setValorizando(null)
    setQuitandoId(null)
    setAjustando(null)
    setAviso(null)
    setEditando(repuesto)
  }

  function empezarValorizar(repuesto: Repuesto) {
    quitar.reset()
    setCreando(false)
    setEditando(null)
    setQuitandoId(null)
    setAjustando(null)
    setAviso(null)
    setValorizando(repuesto)
  }

  function empezarQuitar(repuesto: Repuesto) {
    quitar.reset()
    setCreando(false)
    setEditando(null)
    setValorizando(null)
    setAjustando(null)
    setAviso(null)
    setQuitandoId(repuesto.id)
  }

  function empezarAjuste(repuesto: Repuesto) {
    quitar.reset()
    setCreando(false)
    setEditando(null)
    setValorizando(null)
    setQuitandoId(null)
    setAviso(null)
    setAjustando(repuesto)
  }

  function guardado() {
    setCreando(false)
    setPagina(1)
    setAviso(esAdministrador
      ? 'Repuesto agregado a la orden.'
      : 'Avisaste a administración que usaste este repuesto.')
  }

  const quitados = esAdministrador ? (repuestos.data?.quitados ?? []) : []

  return (
    <section className="repuestos">
      <header className="encabezado">
        <h2>{esAdministrador ? 'Repuestos comprados' : 'Repuestos'}</h2>
        {ordenAbierta && !creando && <button onClick={empezarCarga}>
          {esAdministrador ? 'Agregar repuesto' : 'Avisar repuesto usado'}
        </button>}
      </header>
      {!ordenAbierta && <p className="estado">Esta orden ya no admite cambios en los repuestos.</p>}
      {aviso && <p className="aviso" role="status">{aviso}</p>}
      {creando && ordenAbierta && (esAdministrador
        ? <NuevoRepuestoForm ordenId={ordenId} onCancelar={() => setCreando(false)} onGuardado={guardado} />
        : <AvisoRepuestoForm ordenId={ordenId} onCancelar={() => setCreando(false)} onGuardado={guardado} />)}
      {esAdministrador && editando && ordenAbierta && <EditarRepuestoForm key={editando.id} ordenId={ordenId} repuesto={editando}
        onCancelar={() => setEditando(null)} onGuardado={() => {
          const pendiente = editando?.estado === 'pendiente_de_valorizar'
          setEditando(null)
          setAviso(pendiente ? 'Repuesto corregido.' : 'Repuesto corregido. El precio al cliente se recalculó.')
        }} />}
      {esAdministrador && valorizando && <ValorizarRepuestoForm key={valorizando.id} ordenId={ordenId} repuesto={valorizando}
        onCancelar={() => setValorizando(null)} onGuardado={() => setValorizando(null)} />}
      {repuestos.isPending && <Cargando />}
      {repuestos.isError && <p className="error" role="alert">
        {errorMessage(repuestos.error, 'No se pudieron cargar los repuestos.')}
      </p>}
      {repuestos.data?.repuestos.length === 0 && <p className="estado">
        {esAdministrador && quitados.length > 0
          ? 'No hay repuestos vigentes en esta orden.'
          : esAdministrador
            ? 'Todavía no hay compras registradas en esta orden.'
            : 'Todavía no hay repuestos cargados en esta orden.'}
      </p>}
      {repuestos.data && <>
        <ul className="lista">
          {repuestos.data.repuestos.map((repuesto) => <li key={repuesto.id} className="tarjeta item-datos">
            <strong>{repuesto.descripcion}</strong>
            {!esAdministrador ? (
              <>
                <span className={`insignia insignia-${repuesto.estado}`}>
                  {ESTADO_REPUESTO_LABELS[repuesto.estado]}
                </span>
                <span>Cantidad: {repuesto.cantidad}</span>
                <span>Cargado por {repuesto.registrado_por.nombre} · {fechaHora(repuesto.created_at)}</span>
              </>
            ) : repuesto.estado === 'pendiente_de_valorizar' ? (
              <>
                <span className="insignia insignia-pendiente_de_valorizar">
                  {ESTADO_REPUESTO_LABELS[repuesto.estado]}
                </span>
                <span>Cantidad: {repuesto.cantidad}</span>
                <span>Avisado por {repuesto.registrado_por.nombre} · {fechaHora(repuesto.created_at)}</span>
              </>
            ) : (
              <>
                <span>{repuesto.cantidad} × $ {importe(repuesto.costo_unitario!)} · Margen: {importe(repuesto.margen!)}%</span>
                {repuesto.proveedor && <span>Proveedor: {repuesto.proveedor}</span>}
                <span>Precio al cliente: $ {importe(repuesto.precio_cliente!)} · Ganancia: $ {importe(repuesto.ganancia!)}</span>
                {(repuesto.ajustes?.length ?? 0) > 0 && (
                  <span>
                    Precio vigente: $ {importe(repuesto.precio_vigente!)} · Costo vigente: $ {importe(repuesto.costo_vigente!)} · Ganancia vigente: $ {importe(repuesto.ganancia_vigente!)}
                  </span>
                )}
                <span>Cargado por {repuesto.registrado_por.nombre} · {fechaHora(repuesto.created_at)}</span>
                <HistorialAjustes ajustes={repuesto.ajustes ?? []} />
                {ordenAbierta && (repuesto.cantidad_disponible ?? 0) === 0 && (
                  <span>Todas las unidades fueron devueltas o cambiadas.</span>
                )}
              </>
            )}
            <ComprobanteRepuesto ordenId={ordenId} repuesto={repuesto} puedeAdjuntar={ordenAbierta} />
            {esAdministrador && ordenAbierta && quitandoId === repuesto.id ? (
              <ConfirmacionQuitar repuesto={repuesto} pendiente={quitar.isPending}
                error={quitar.isError ? quitar.error : null}
                onCancelar={() => {
                  quitar.reset()
                  setQuitandoId(null)
                }}
                onConfirmar={() => quitar.mutate(repuesto.id)} />
            ) : esAdministrador && ordenAbierta && (
              <>
                <div className="acciones item-acciones">
                  <button type="button" className="secundario" onClick={() => empezarEdicion(repuesto)}>Corregir</button>
                  {repuesto.estado === 'pendiente_de_valorizar' && (
                    <button type="button" className="secundario" onClick={() => empezarValorizar(repuesto)}>Cargar costo</button>
                  )}
                  {repuesto.estado === 'valorizado' && (repuesto.cantidad_disponible ?? 0) > 0 && (
                    <button type="button" className="secundario" onClick={() => empezarAjuste(repuesto)}>
                      Registrar devolución o cambio
                    </button>
                  )}
                  <button type="button" className="secundario peligro" onClick={() => empezarQuitar(repuesto)}>Quitar</button>
                </div>
                {ajustando?.id === repuesto.id && (
                  <RegistrarAjusteForm
                    key={repuesto.id}
                    ordenId={ordenId}
                    repuesto={repuesto}
                    onCancelar={() => setAjustando(null)}
                    onGuardado={(tipo: TipoAjuste) => {
                      setAjustando(null)
                      setAviso(tipo === 'devolucion'
                        ? 'Devolución registrada. El repuesto original queda en el historial.'
                        : 'Cambio registrado. El repuesto original queda en el historial.')
                    }}
                  />
                )}
              </>
            )}
          </li>)}
        </ul>
        <Paginacion meta={repuestos.data.meta} cargando={repuestos.isFetching} onCambiar={setPagina} />
      </>}
      {esAdministrador && quitados.length > 0 && <section className="repuestos-quitados">
        <h2>Bajas registradas</h2>
        <ul className="lista">
          {quitados.map((repuesto) => <li key={repuesto.id} className="tarjeta item-datos repuesto-quitado">
            <strong>{repuesto.descripcion}</strong>
            <span>Cantidad: {repuesto.cantidad}</span>
            {repuesto.estado === 'valorizado' && <span>
              {repuesto.cantidad} × $ {importe(repuesto.costo_unitario!)} · Precio al cliente: $ {importe(repuesto.precio_cliente!)}
            </span>}
            {repuesto.proveedor && <span>Proveedor: {repuesto.proveedor}</span>}
            <span>
              Quitado por {repuesto.quitado_por?.nombre ?? 'administración'}
              {repuesto.quitado_en && ` · ${fechaHora(repuesto.quitado_en)}`}
            </span>
            <ComprobanteRepuesto ordenId={ordenId} repuesto={repuesto} puedeAdjuntar={false} />
          </li>)}
        </ul>
      </section>}
    </section>
  )
}

function ConfirmacionQuitar({ repuesto, pendiente, error, onCancelar, onConfirmar }: {
  repuesto: Repuesto
  pendiente: boolean
  error: unknown
  onCancelar: () => void
  onConfirmar: () => void
}) {
  const errores = fieldErrors(error)
  const mensaje = errores.base?.join('. ')
    ?? errores.orden?.join('. ')
    ?? errores.estado?.join('. ')
    ?? (error ? errorMessage(error, 'No se pudo quitar el repuesto.') : null)

  return (
    <div className="confirmacion-baja" role="group" aria-label={`Quitar ${repuesto.descripcion}`}>
      <p>
        ¿Quitar {repuesto.descripcion} de la orden? Deja de sumar al total. La baja queda registrada y no se puede deshacer.
      </p>
      {mensaje && <p className="error" role="alert">{mensaje}</p>}
      <div className="acciones">
        <button type="button" className="secundario" disabled={pendiente} onClick={onCancelar}>No quitar</button>
        <button type="button" className="peligro" disabled={pendiente} onClick={onConfirmar}>
          {pendiente ? 'Quitando…' : 'Sí, quitar el repuesto'}
        </button>
      </div>
    </div>
  )
}

function HistorialAjustes({ ajustes }: { ajustes: AjusteRepuesto[] }) {
  if (ajustes.length === 0) return null

  return (
    <ul className="historial-ajustes">
      {ajustes.map((ajuste) => (
        <li key={ajuste.id}>
          <span>{describirAjuste(ajuste)}</span>
          <span>{ajuste.motivo}</span>
          <span>{ajuste.registrado_por.nombre} · {fechaHora(ajuste.registrado_en)}</span>
        </li>
      ))}
    </ul>
  )
}

function describirAjuste(ajuste: AjusteRepuesto) {
  const efecto = `ajuste al cliente $ ${importe(ajuste.ajuste_precio_cliente)}`
  if (ajuste.tipo === 'devolucion') {
    return `Devolución de ${ajuste.cantidad} u. · costo acreditado $ ${importe(ajuste.costo_unitario)} · ${efecto}`
  }
  return `Cambio de ${ajuste.cantidad} u. · costo del reemplazo $ ${importe(ajuste.costo_unitario)} · ${efecto}`
}
