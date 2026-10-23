import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { fechaHora, importe } from '../../lib/formato'
import { useAuth } from '../auth/AuthContext'
import { AvisoRepuestoForm } from './AvisoRepuestoForm'
import { listarRepuestos, ESTADO_REPUESTO_LABELS, type Repuesto } from './api'
import { NuevoRepuestoForm } from './NuevoRepuestoForm'
import { ValorizarRepuestoForm } from './ValorizarRepuestoForm'

export function RepuestosPanel({ ordenId, ordenAbierta }: { ordenId: number; ordenAbierta: boolean }) {
  const { usuario } = useAuth()
  const esAdministrador = usuario?.rol === 'administrador'
  const [creando, setCreando] = useState(false)
  const [pagina, setPagina] = useState(1)
  const [aviso, setAviso] = useState(false)
  const [valorizando, setValorizando] = useState<Repuesto | null>(null)

  const repuestos = useQuery({
    queryKey: ['repuestos', ordenId, pagina],
    queryFn: () => listarRepuestos(ordenId, pagina),
  })

  function guardado() {
    setCreando(false)
    setPagina(1)
    setAviso(true)
  }

  return (
    <section className="repuestos">
      <header className="encabezado">
        <h2>{esAdministrador ? 'Repuestos comprados' : 'Repuestos'}</h2>
        {ordenAbierta && !creando && <button onClick={() => {
          setAviso(false)
          setCreando(true)
        }}>{esAdministrador ? 'Agregar repuesto' : 'Avisar repuesto usado'}</button>}
      </header>
      {aviso && <p className="aviso" role="status">
        {esAdministrador ? 'Repuesto agregado a la orden.' : 'Avisaste a administración que usaste este repuesto.'}
      </p>}
      {creando && ordenAbierta && (esAdministrador
        ? <NuevoRepuestoForm ordenId={ordenId} onCancelar={() => setCreando(false)} onGuardado={guardado} />
        : <AvisoRepuestoForm ordenId={ordenId} onCancelar={() => setCreando(false)} onGuardado={guardado} />)}
      {valorizando && <ValorizarRepuestoForm key={valorizando.id} ordenId={ordenId} repuesto={valorizando}
        onCancelar={() => setValorizando(null)} onGuardado={() => setValorizando(null)} />}
      {repuestos.isPending && <p className="estado">Cargando repuestos…</p>}
      {repuestos.isError && <p className="error" role="alert">
        {errorMessage(repuestos.error, 'No se pudieron cargar los repuestos.')}
      </p>}
      {repuestos.data?.repuestos.length === 0 && <p className="estado">Todavía no hay repuestos cargados en esta orden.</p>}
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
                {ordenAbierta && <button className="secundario" onClick={() => setValorizando(repuesto)}>Cargar costo</button>}
              </>
            ) : (
              <>
                <span>{repuesto.cantidad} × $ {importe(repuesto.costo_unitario!)} · Margen: {importe(repuesto.margen!)}%</span>
                {repuesto.proveedor && <span>Proveedor: {repuesto.proveedor}</span>}
                <span>Precio al cliente: $ {importe(repuesto.precio_cliente!)} · Ganancia: $ {importe(repuesto.ganancia!)}</span>
                <span>Cargado por {repuesto.registrado_por.nombre} · {fechaHora(repuesto.created_at)}</span>
              </>
            )}
          </li>)}
        </ul>
        <Paginacion meta={repuestos.data.meta} cargando={repuestos.isFetching} onCambiar={setPagina} />
      </>}
    </section>
  )
}
