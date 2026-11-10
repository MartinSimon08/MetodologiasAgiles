import { useQuery } from '@tanstack/react-query'
import { useSearchParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { obtenerReporteTareasPorMecanico } from './api'
import { ReportesNav } from './ReportesNav'

function hoyIso() {
  return new Date().toISOString().slice(0, 10)
}

function primerDiaDelMesIso() {
  const hoy = new Date()
  return new Date(hoy.getFullYear(), hoy.getMonth(), 1).toISOString().slice(0, 10)
}

export function ReporteTareasPorMecanicoPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const desde = searchParams.get('desde') ?? primerDiaDelMesIso()
  const hasta = searchParams.get('hasta') ?? hoyIso()

  const reporte = useQuery({
    queryKey: ['reporte-tareas-por-mecanico', desde, hasta],
    queryFn: () => obtenerReporteTareasPorMecanico({ desde, hasta }),
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
        titulo="Tareas por mecánico"
        bajada="Cantidad de tareas que tomó y completó cada mecánico en el período elegido."
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
        <ul className="lista" aria-busy={reporte.isFetching}>
          {reporte.data.mecanicos.map((fila) => (
            <li key={fila.mecanico.id} className="tarjeta fila-item">
              <div className="item-datos">
                <strong>{fila.mecanico.nombre}</strong>
              </div>
              <span>{fila.tomadas} {fila.tomadas === 1 ? 'tomada' : 'tomadas'}</span>
              <span>{fila.completadas} {fila.completadas === 1 ? 'completada' : 'completadas'}</span>
            </li>
          ))}
        </ul>
      )}

      {reporte.data && reporte.data.mecanicos.length === 0 && (
        <p className="estado">No hay mecánicos registrados.</p>
      )}
    </section>
  )
}
