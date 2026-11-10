import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { fechaHora, importe } from '../../lib/formato'
import { AseguradoraSelector } from '../aseguradoras/AseguradoraSelector'
import { consultarCasosAseguradora, type CasoAseguradora, type TotalesCasosAseguradora } from './api'
import { CasosNav } from './CasosNav'

function hoyIso() {
  return new Date().toISOString().slice(0, 10)
}

function primerDiaDelMesIso() {
  const hoy = new Date()
  return new Date(hoy.getFullYear(), hoy.getMonth(), 1).toISOString().slice(0, 10)
}

export function CasosAseguradoraPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const [aseguradoraId, setAseguradoraId] = useState<number | null>(null)
  const desde = searchParams.get('desde') ?? primerDiaDelMesIso()
  const hasta = searchParams.get('hasta') ?? hoyIso()

  const consulta = useQuery({
    queryKey: ['casos-aseguradora', aseguradoraId, desde, hasta],
    queryFn: () => consultarCasosAseguradora({ aseguradoraId: aseguradoraId!, desde, hasta }),
    enabled: aseguradoraId !== null,
  })

  const errores = fieldErrors(consulta.error)

  function actualizar(valores: { desde?: string; hasta?: string }) {
    const params: Record<string, string> = {
      desde: valores.desde ?? desde,
      hasta: valores.hasta ?? hasta,
    }
    setSearchParams(params, { replace: true })
  }

  return (
    <section className="casos">
      <CasosNav />
      <EncabezadoPagina
        titulo="Casos por aseguradora"
        bajada="Casos abiertos en el período, con el total autorizado de cada orden, la franquicia cobrada y el saldo pendiente de facturar."
      />

      <AseguradoraSelector
        etiqueta="Aseguradora"
        valor={aseguradoraId}
        onCambiar={setAseguradoraId}
        errores={errores.aseguradora}
      />

      <form className="filtros-compras" onSubmit={(event) => event.preventDefault()}>
        <label>
          <span>Desde</span>
          <input
            type="date"
            value={desde}
            max={hasta}
            onChange={(event) => actualizar({ desde: event.target.value })}
            aria-invalid={Boolean(errores.desde)}
          />
          <ErroresCampo errores={errores.desde} />
        </label>
        <label>
          <span>Hasta</span>
          <input
            type="date"
            value={hasta}
            min={desde}
            onChange={(event) => actualizar({ hasta: event.target.value })}
            aria-invalid={Boolean(errores.hasta)}
          />
          <ErroresCampo errores={errores.hasta} />
        </label>
      </form>

      {aseguradoraId === null && <p className="estado">Elegí una aseguradora para ver sus casos.</p>}
      {consulta.isPending && aseguradoraId !== null && <Cargando />}
      {consulta.isError && !errores.desde && !errores.hasta && !errores.aseguradora && (
        <p className="error" role="alert">
          {errorMessage(consulta.error, 'No se pudieron cargar los casos.')}
        </p>
      )}

      {consulta.data && (
        <>
          {consulta.data.casos.length === 0 && (
            <p className="estado">No hay casos de esta aseguradora en el período.</p>
          )}
          {consulta.data.casos.length > 0 && (
            <ul className="lista" aria-busy={consulta.isFetching}>
              {consulta.data.casos.map((caso) => (
                <CasoAseguradoraItem key={caso.id} caso={caso} />
              ))}
            </ul>
          )}
          <TotalesPeriodo totales={consulta.data.totales} cargando={consulta.isFetching} />
        </>
      )}
    </section>
  )
}

function CasoAseguradoraItem({ caso }: { caso: CasoAseguradora }) {
  const vehiculo = [caso.vehiculo.marca, caso.vehiculo.modelo].filter(Boolean).join(' ')

  return (
    <li className="tarjeta">
      <div className="item-datos">
        <strong>Siniestro {caso.numero_siniestro}</strong>
        <span>
          {caso.asegurado.nombre} · <span className="patente">{caso.vehiculo.patente}</span>
          {vehiculo && ` ${vehiculo}`}
        </span>
        <span>Abierto el {fechaHora(caso.created_at)}</span>
        {caso.orden_id === null && <span className="insignia insignia-desactivado">Sin orden</span>}
      </div>
      <Importes
        totalAutorizado={caso.total_autorizado}
        franquiciaCobrada={caso.franquicia_cobrada}
        saldoPendiente={caso.saldo_pendiente}
      />
    </li>
  )
}

function TotalesPeriodo({ totales, cargando }: { totales: TotalesCasosAseguradora; cargando: boolean }) {
  return (
    <section className="tarjeta" aria-busy={cargando}>
      <h2>Totales del período</h2>
      <Importes
        totalAutorizado={totales.total_autorizado}
        franquiciaCobrada={totales.franquicia_cobrada}
        saldoPendiente={totales.saldo_pendiente}
      />
    </section>
  )
}

function Importes({
  totalAutorizado,
  franquiciaCobrada,
  saldoPendiente,
}: {
  totalAutorizado: string
  franquiciaCobrada: string
  saldoPendiente: string
}) {
  return (
    <dl className="totales-cierre">
      <div>
        <dt>Total autorizado</dt>
        <dd>$ {importe(totalAutorizado)}</dd>
      </div>
      <div>
        <dt>Franquicia cobrada</dt>
        <dd>$ {importe(franquiciaCobrada)}</dd>
      </div>
      <div>
        <dt>Saldo pendiente</dt>
        <dd>$ {importe(saldoPendiente)}</dd>
      </div>
    </dl>
  )
}
