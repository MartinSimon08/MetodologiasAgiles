import { useQuery } from '@tanstack/react-query'
import { useSearchParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { importe } from '../../lib/formato'
import { obtenerReporteIngresos } from './api'
import { ReportesNav } from './ReportesNav'

function hoyIso() {
  return new Date().toISOString().slice(0, 10)
}

function primerDiaDelMesIso() {
  const hoy = new Date()
  return new Date(hoy.getFullYear(), hoy.getMonth(), 1).toISOString().slice(0, 10)
}

export function ReporteIngresosPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const desde = searchParams.get('desde') ?? primerDiaDelMesIso()
  const hasta = searchParams.get('hasta') ?? hoyIso()

  const reporte = useQuery({
    queryKey: ['reporte-ingresos', desde, hasta],
    queryFn: () => obtenerReporteIngresos({ desde, hasta }),
  })

  const errores = fieldErrors(reporte.error)

  function actualizar(valores: { desde?: string; hasta?: string }) {
    const params: Record<string, string> = {
      desde: valores.desde ?? desde,
      hasta: valores.hasta ?? hasta,
    }
    setSearchParams(params, { replace: true })
  }

  return (
    <section className="reportes">
      <ReportesNav />
      <EncabezadoPagina
        titulo="Ingresos por período"
        bajada="Adelantos registrados en el período, separados entre franquicia, saldo facturado a aseguradoras y clientes directos."
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

      {reporte.isPending && <Cargando />}
      {reporte.isError && !errores.desde && !errores.hasta && (
        <p className="error" role="alert">
          {errorMessage(reporte.error, 'No se pudo calcular el reporte.')}
        </p>
      )}

      {reporte.data && (
        <>
          <dl className="totales-cierre" aria-busy={reporte.isFetching}>
            <div>
              <dt>Franquicia cobrada</dt>
              <dd>$ {importe(reporte.data.franquicia_cobrada)}</dd>
            </div>
            <div>
              <dt>Saldo facturado a aseguradoras</dt>
              <dd>$ {importe(reporte.data.saldo_facturado_aseguradoras)}</dd>
            </div>
            <div>
              <dt>Ingresos de clientes directos</dt>
              <dd>$ {importe(reporte.data.ingresos_clientes_directos)}</dd>
            </div>
            <div className="total">
              <dt>Total de ingresos</dt>
              <dd>$ {importe(reporte.data.total_ingresos)}</dd>
            </div>
          </dl>
          <p className="resumen-saldo" role="status" aria-busy={reporte.isFetching}>
            <span>Saldo pendiente de aseguradoras</span>
            <strong>$ {importe(reporte.data.saldo_pendiente_aseguradoras)}</strong>
          </p>
          <p className="bajada">No entra en el total de ingresos cobrados.</p>
        </>
      )}
    </section>
  )
}
