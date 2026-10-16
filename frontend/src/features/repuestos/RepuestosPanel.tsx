import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage, fieldErrors } from '../../lib/api'
import { fechaHora, importe } from '../../lib/formato'
import { useAuth } from '../auth/AuthContext'
import { AvisoRepuestoForm } from './AvisoRepuestoForm'
import { listarRepuestos, quitarRepuesto, ESTADO_REPUESTO_LABELS, type Repuesto } from './api'
import { EditarRepuestoForm } from './EditarRepuestoForm'
import { NuevoRepuestoForm } from './NuevoRepuestoForm'
import { ValorizarRepuestoForm } from './ValorizarRepuestoForm'

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

  const repuestos = useQuery({
    queryKey: ['repuestos', ordenId, pagina],
    queryFn: () => listarRepuestos(ordenId, pagina),
    enabled: esAdministrador,
  })
  const quitar = useMutation({
    mutationFn: (id: number) => quitarRepuesto(ordenId, id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['repuestos', ordenId] })
      queryClient.invalidateQueries({ queryKey: ['adelantos', ordenId] })
      setQuitandoId(null)
      setAviso('Repuesto quitado. La baja quedó registrada.')
    },
  })

  function empezarCarga() {
    quitar.reset()
    setEditando(null)
    setValorizando(null)
    setQuitandoId(null)
    setAviso(null)
    setCreando(true)
  }

  function empezarEdicion(repuesto: Repuesto) {
    quitar.reset()
    setCreando(false)
    setValorizando(null)
    setQuitandoId(null)
    setAviso(null)
    setEditando(repuesto)
  }

  function empezarValorizar(repuesto: Repuesto) {
    quitar.reset()
    setCreando(false)
    setEditando(null)
    setQuitandoId(null)
    setAviso(null)
    setValorizando(repuesto)
  }

  function empezarQuitar(repuesto: Repuesto) {
    quitar.reset()
    setCreando(false)
    setEditando(null)
    setValorizando(null)
    setAviso(null)
    setQuitandoId(repuesto.id)
  }

  if (!esAdministrador) {
    return (
      <section className="repuestos">
        <header className="encabezado">
          <h2>Repuestos</h2>
          {ordenAbierta && !creando && <button onClick={empezarCarga}>Avisar repuesto usado</button>}
        </header>
        {!ordenAbierta && <p className="estado">Esta orden ya no admite cambios en los repuestos.</p>}
        {aviso && <p className="aviso" role="status">{aviso}</p>}
        {creando && ordenAbierta && <AvisoRepuestoForm ordenId={ordenId} onCancelar={() => setCreando(false)}
          onGuardado={() => {
            setCreando(false)
            setAviso('Avisaste a administración que usaste este repuesto.')
          }} />}
      </section>
    )
  }

  const quitados = repuestos.data?.quitados ?? []

  return (
    <section className="repuestos">
      <header className="encabezado">
        <h2>Repuestos comprados</h2>
        {ordenAbierta && !creando && <button onClick={empezarCarga}>Agregar repuesto</button>}
      </header>
      {!ordenAbierta && <p className="estado">Esta orden ya no admite cambios en los repuestos.</p>}
      {aviso && <p className="aviso" role="status">{aviso}</p>}
      {creando && ordenAbierta && <NuevoRepuestoForm ordenId={ordenId}
        onCancelar={() => setCreando(false)}
        onGuardado={() => {
          setCreando(false)
          setPagina(1)
          setAviso('Repuesto agregado a la orden.')
        }} />}
      {editando && ordenAbierta && <EditarRepuestoForm key={editando.id} ordenId={ordenId} repuesto={editando}
        onCancelar={() => setEditando(null)} onGuardado={() => {
          const pendiente = editando?.estado === 'pendiente_de_valorizar'
          setEditando(null)
          setAviso(pendiente ? 'Repuesto corregido.' : 'Repuesto corregido. El precio al cliente se recalculó.')
        }} />}
      {valorizando && <ValorizarRepuestoForm key={valorizando.id} ordenId={ordenId} repuesto={valorizando}
        onCancelar={() => setValorizando(null)} onGuardado={() => setValorizando(null)} />}
      {repuestos.isPending && <p className="estado">Cargando repuestos…</p>}
      {repuestos.isError && <p className="error" role="alert">
        {errorMessage(repuestos.error, 'No se pudieron cargar los repuestos.')}
      </p>}
      {repuestos.data?.repuestos.length === 0 && <p className="estado">
        {quitados.length > 0
          ? 'No hay repuestos vigentes en esta orden.'
          : 'Todavía no hay compras registradas en esta orden.'}
      </p>}
      {repuestos.data && <>
        <ul className="lista">
          {repuestos.data.repuestos.map((repuesto) => <li key={repuesto.id} className="tarjeta item-datos">
            <strong>{repuesto.descripcion}</strong>
            {repuesto.estado === 'pendiente_de_valorizar' ? (
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
                <span>Cargado por {repuesto.registrado_por.nombre} · {fechaHora(repuesto.created_at)}</span>
              </>
            )}
            {ordenAbierta && quitandoId === repuesto.id ? (
              <ConfirmacionQuitar repuesto={repuesto} pendiente={quitar.isPending}
                error={quitar.isError ? quitar.error : null}
                onCancelar={() => {
                  quitar.reset()
                  setQuitandoId(null)
                }}
                onConfirmar={() => quitar.mutate(repuesto.id)} />
            ) : ordenAbierta && (
              <div className="acciones item-acciones">
                <button type="button" className="secundario" onClick={() => empezarEdicion(repuesto)}>Corregir</button>
                {repuesto.estado === 'pendiente_de_valorizar' && (
                  <button type="button" className="secundario" onClick={() => empezarValorizar(repuesto)}>Cargar costo</button>
                )}
                <button type="button" className="secundario peligro" onClick={() => empezarQuitar(repuesto)}>Quitar</button>
              </div>
            )}
          </li>)}
        </ul>
        <Paginacion meta={repuestos.data.meta} cargando={repuestos.isFetching} onCambiar={setPagina} />
      </>}
      {quitados.length > 0 && <section className="repuestos-quitados">
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
