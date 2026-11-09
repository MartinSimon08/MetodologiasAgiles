import { useQuery } from '@tanstack/react-query'
import { useSearchParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { importe } from '../../lib/formato'
import { obtenerReporteMargenRepuestos } from './api'
import { ReportesNav } from './ReportesNav'

function hoyIso() {
  return new Date().toISOString().slice(0, 10)
}

function primerDiaDelMesIso() {
  const hoy = new Date()
  return new Date(hoy.getFullYear(), hoy.getMonth(), 1).toISOString().slice(0, 10)
}

export function ReporteMargenRepuestosPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const desde = searchParams.get('desde') ?? primerDiaDelMesIso()
  const hasta = searchParams.get('hasta') ?? hoyIso()

  const reporte = useQuery({
    queryKey: ['reporte-margen-repuestos', desde, hasta],
    queryFn: () => obtenerReporteMargenRepuestos({ desde, hasta }),
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
        titulo="Margen de repuestos"
        bajada="Diferencia entre el precio de venta y el costo de compra de los repuestos de las órdenes abiertas en el período."
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
        <p className="resumen-saldo" role="status" aria-busy={reporte.isFetching}>
          <span>Margen total</span>
          <strong>$ {importe(reporte.data.margen_total)}</strong>
        </p>
      )}
    </section>
  )
}
