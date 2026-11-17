import { useQuery } from '@tanstack/react-query'
import { useSearchParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { EstadoVacio } from '../../components/EstadoVacio'
import { Tabla } from '../../components/Tabla'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { hoyIso, primerDiaDelMesIso } from '../../lib/fechas'
import { obtenerReporteTareasPorMecanico } from './api'
import { ReportesNav } from './ReportesNav'

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

      {reporte.data && reporte.data.mecanicos.length > 0 && (
        <Tabla etiqueta="Tareas por mecánico" ocupada={reporte.isFetching}>
          <thead>
            <tr>
              <th scope="col">Mecánico</th>
              <th scope="col" className="numero">
                Tomadas
              </th>
              <th scope="col" className="numero">
                Completadas
              </th>
            </tr>
          </thead>
          <tbody>
            {reporte.data.mecanicos.map((fila) => (
              <tr key={fila.mecanico.id}>
                <td>{fila.mecanico.nombre}</td>
                <td className="numero">{fila.tomadas}</td>
                <td className="numero">{fila.completadas}</td>
              </tr>
            ))}
          </tbody>
        </Tabla>
      )}

      {reporte.data && reporte.data.mecanicos.length === 0 && (
        <EstadoVacio titulo="No hay mecánicos registrados" descripcion="Creá usuarios con rol mecánico para ver sus tareas." />
      )}
    </section>
  )
}
