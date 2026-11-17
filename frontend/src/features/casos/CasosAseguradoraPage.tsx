import { useQuery } from '@tanstack/react-query'
import { Link, useSearchParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { ErroresCampo } from '../../components/ErroresCampo'
import { EstadoVacio } from '../../components/EstadoVacio'
import { Tabla } from '../../components/Tabla'
import { errorMessage, fieldErrors } from '../../lib/api'
import { hoyIso, primerDiaDelMesIso } from '../../lib/fechas'
import { fechaHora, importe } from '../../lib/formato'
import { AseguradoraSelector } from '../aseguradoras/AseguradoraSelector'
import { consultarCasosAseguradora } from './api'
import { CasosNav } from './CasosNav'

export function CasosAseguradoraPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const aseguradoraParam = Number(searchParams.get('aseguradora'))
  const aseguradoraId = Number.isInteger(aseguradoraParam) && aseguradoraParam > 0 ? aseguradoraParam : null
  const desde = searchParams.get('desde') ?? primerDiaDelMesIso()
  const hasta = searchParams.get('hasta') ?? hoyIso()

  const consulta = useQuery({
    queryKey: ['casos-aseguradora', aseguradoraId, desde, hasta],
    queryFn: () => consultarCasosAseguradora({ aseguradoraId: aseguradoraId!, desde, hasta }),
    enabled: aseguradoraId !== null,
  })

  const errores = fieldErrors(consulta.error)

  function actualizar(valores: { aseguradora?: number | null; desde?: string; hasta?: string }) {
    const aseguradora = valores.aseguradora === undefined ? aseguradoraId : valores.aseguradora
    const params: Record<string, string> = {
      desde: valores.desde ?? desde,
      hasta: valores.hasta ?? hasta,
    }
    if (aseguradora !== null) params.aseguradora = String(aseguradora)
    setSearchParams(params, { replace: true })
  }

  return (
    <section className="casos">
      <EncabezadoPagina
        titulo="Casos por aseguradora"
        bajada="Casos abiertos en el período, con el total autorizado de cada orden, la franquicia cobrada y el saldo pendiente de facturar."
      />
      <CasosNav />

      <AseguradoraSelector
        etiqueta="Aseguradora"
        valor={aseguradoraId}
        inicial={consulta.data?.aseguradora}
        incluirDesactivadas
        onCambiar={(id) => actualizar({ aseguradora: id })}
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

      {consulta.data && consulta.data.casos.length === 0 && (
        <EstadoVacio busqueda titulo="Sin casos" descripcion="No hay casos de esta aseguradora en el período." />
      )}

      {consulta.data && consulta.data.casos.length > 0 && (
        <Tabla etiqueta="Casos de la aseguradora" ocupada={consulta.isFetching}>
          <thead>
            <tr>
              <th scope="col">Siniestro</th>
              <th scope="col">Asegurado</th>
              <th scope="col">Abierto</th>
              <th scope="col">Orden</th>
              <th scope="col" className="numero">
                Total autorizado
              </th>
              <th scope="col" className="numero">
                Franquicia cobrada
              </th>
              <th scope="col" className="numero">
                Saldo pendiente
              </th>
            </tr>
          </thead>
          <tbody>
            {consulta.data.casos.map((caso) => {
              const vehiculo = [caso.vehiculo.marca, caso.vehiculo.modelo].filter(Boolean).join(' ')
              return (
                <tr key={caso.id}>
                  <td>
                    <strong>{caso.numero_siniestro}</strong>
                  </td>
                  <td>
                    {caso.asegurado.nombre}
                    <span className="secundaria">
                      <span className="patente">{caso.vehiculo.patente}</span>
                      {vehiculo && ` ${vehiculo}`}
                    </span>
                  </td>
                  <td className="fecha">{fechaHora(caso.created_at)}</td>
                  <td>
                    {caso.orden_id === null ? (
                      <span className="insignia insignia-desactivado">Sin orden</span>
                    ) : caso.orden_estado === 'cancelada' ? (
                      <span className="insignia insignia-desactivado">Orden cancelada</span>
                    ) : (
                      <Link to={`/ordenes/${caso.orden_id}`} className="enlace-fila">
                        #{caso.orden_id}
                      </Link>
                    )}
                  </td>
                  <td className="numero">$ {importe(caso.total_autorizado)}</td>
                  <td className="numero">$ {importe(caso.franquicia_cobrada)}</td>
                  <td className="numero">$ {importe(caso.saldo_pendiente)}</td>
                </tr>
              )
            })}
          </tbody>
          <tfoot>
            <tr>
              <th scope="row" colSpan={4}>
                Totales del período
              </th>
              <td className="numero">$ {importe(consulta.data.totales.total_autorizado)}</td>
              <td className="numero">$ {importe(consulta.data.totales.franquicia_cobrada)}</td>
              <td className="numero">$ {importe(consulta.data.totales.saldo_pendiente)}</td>
            </tr>
          </tfoot>
        </Tabla>
      )}
    </section>
  )
}
