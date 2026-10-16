import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { fechaHora, importe } from '../../lib/formato'
import { useAuth } from '../auth/AuthContext'
import { AvisoRepuestoForm } from './AvisoRepuestoForm'
import { listarRepuestos, ESTADO_REPUESTO_LABELS, type AjusteRepuesto, type Repuesto, type TipoAjuste } from './api'
import { NuevoRepuestoForm } from './NuevoRepuestoForm'
import { RegistrarAjusteForm } from './RegistrarAjusteForm'
import { ValorizarRepuestoForm } from './ValorizarRepuestoForm'

export function RepuestosPanel({ ordenId, ordenAbierta }: { ordenId: number; ordenAbierta: boolean }) {
  const { usuario } = useAuth()
  const esAdministrador = usuario?.rol === 'administrador'
  const [creando, setCreando] = useState(false)
  const [pagina, setPagina] = useState(1)
  const [aviso, setAviso] = useState(false)
  const [avisoAjuste, setAvisoAjuste] = useState<string | null>(null)
  const [valorizando, setValorizando] = useState<Repuesto | null>(null)
  const [ajustando, setAjustando] = useState<Repuesto | null>(null)

  const repuestos = useQuery({
    queryKey: ['repuestos', ordenId, pagina],
    queryFn: () => listarRepuestos(ordenId, pagina),
    enabled: esAdministrador,
  })

  if (!esAdministrador) {
    return (
      <section className="repuestos">
        <header className="encabezado">
          <h2>Repuestos</h2>
          {ordenAbierta && !creando && <button onClick={() => {
            setAviso(false)
            setCreando(true)
          }}>Avisar repuesto usado</button>}
        </header>
        {aviso && <p className="aviso" role="status">Avisaste a administración que usaste este repuesto.</p>}
        {creando && ordenAbierta && <AvisoRepuestoForm ordenId={ordenId} onCancelar={() => setCreando(false)}
          onGuardado={() => {
            setCreando(false)
            setAviso(true)
          }} />}
      </section>
    )
  }

  return (
    <section className="repuestos">
      <header className="encabezado">
        <h2>Repuestos comprados</h2>
        {ordenAbierta && !creando && <button onClick={() => {
          setAviso(false)
          setAvisoAjuste(null)
          setAjustando(null)
          setCreando(true)
        }}>Agregar repuesto</button>}
      </header>
      {aviso && <p className="aviso" role="status">Repuesto agregado a la orden.</p>}
      {avisoAjuste && <p className="aviso" role="status">{avisoAjuste}</p>}
      {creando && ordenAbierta && <NuevoRepuestoForm ordenId={ordenId}
        onCancelar={() => setCreando(false)}
        onGuardado={() => {
          setCreando(false)
          setPagina(1)
          setAviso(true)
        }} />}
      {valorizando && <ValorizarRepuestoForm key={valorizando.id} ordenId={ordenId} repuesto={valorizando}
        onCancelar={() => setValorizando(null)} onGuardado={() => setValorizando(null)} />}
      {repuestos.isPending && <p className="estado">Cargando repuestos…</p>}
      {repuestos.isError && <p className="error" role="alert">
        {errorMessage(repuestos.error, 'No se pudieron cargar los repuestos.')}
      </p>}
      {repuestos.data?.repuestos.length === 0 && <p className="estado">Todavía no hay compras registradas en esta orden.</p>}
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
                {ordenAbierta && <button className="secundario" onClick={() => setValorizando(repuesto)}>Cargar costo</button>}
              </>
            ) : (
              <>
                <span>{repuesto.cantidad} × $ {importe(repuesto.costo_unitario!)} · Margen: {importe(repuesto.margen!)}%</span>
                {repuesto.proveedor && <span>Proveedor: {repuesto.proveedor}</span>}
                <span>Precio al cliente: $ {importe(repuesto.precio_cliente!)} · Ganancia: $ {importe(repuesto.ganancia!)}</span>
                {repuesto.ajustes.length > 0 && (
                  <span>
                    Precio vigente: $ {importe(repuesto.precio_vigente!)} · Costo vigente: $ {importe(repuesto.costo_vigente!)} · Ganancia vigente: $ {importe(repuesto.ganancia_vigente!)}
                  </span>
                )}
                <span>Cargado por {repuesto.registrado_por.nombre} · {fechaHora(repuesto.created_at)}</span>
                <HistorialAjustes ajustes={repuesto.ajustes} />
                {ordenAbierta && repuesto.cantidad_disponible > 0 && (
                  <button type="button" className="secundario" onClick={() => {
                    setCreando(false)
                    setValorizando(null)
                    setAviso(false)
                    setAvisoAjuste(null)
                    setAjustando(repuesto)
                  }}>Registrar devolución o cambio</button>
                )}
                {ordenAbierta && repuesto.cantidad_disponible === 0 && (
                  <span>Todas las unidades fueron devueltas o cambiadas.</span>
                )}
                {ajustando?.id === repuesto.id && (
                  <RegistrarAjusteForm
                    key={repuesto.id}
                    ordenId={ordenId}
                    repuesto={repuesto}
                    onCancelar={() => setAjustando(null)}
                    onGuardado={(tipo: TipoAjuste) => {
                      setAjustando(null)
                      setAvisoAjuste(tipo === 'devolucion'
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
    </section>
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
