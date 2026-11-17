import { useQuery } from '@tanstack/react-query'
import { Cargando } from '../../components/Cargando'
import { EstadoVacio } from '../../components/EstadoVacio'
import { Tabla } from '../../components/Tabla'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { errorMessage } from '../../lib/api'
import { obtenerReporteTareasFrecuentes } from './api'
import { ReportesNav } from './ReportesNav'

export function ReporteTareasFrecuentesPage() {
  const reporte = useQuery({
    queryKey: ['reporte-tareas-frecuentes'],
    queryFn: obtenerReporteTareasFrecuentes,
  })

  const maximo = reporte.data?.tareas[0]?.cantidad ?? 0

  return (
    <section className="reportes">
      <ReportesNav />
      <EncabezadoPagina
        titulo="Tareas más frecuentes"
        bajada="Cuántas veces se realizó cada tarea o servicio, de más a menos frecuente."
      />

      {reporte.isPending && <Cargando />}
      {reporte.isError && (
        <p className="error" role="alert">
          {errorMessage(reporte.error, 'No se pudo calcular el reporte.')}
        </p>
      )}

      {reporte.data && reporte.data.tareas.length === 0 && (
        <EstadoVacio
          titulo="Todavía no hay tareas terminadas"
          descripcion="El ranking se arma con las tareas que los mecánicos marcan como terminadas."
        />
      )}

      {reporte.data && reporte.data.tareas.length > 0 && (
        <Tabla etiqueta="Tareas más frecuentes">
          <thead>
            <tr>
              <th scope="col" className="numero">
                #
              </th>
              <th scope="col">Tarea</th>
              <th scope="col" className="numero">
                Veces
              </th>
            </tr>
          </thead>
          <tbody>
            {reporte.data.tareas.map((fila, indice) => (
              <tr key={fila.descripcion}>
                <td className="numero">{indice + 1}</td>
                <td>
                  {fila.descripcion}
                  <span
                    className="barra-frecuencia"
                    style={{ width: `${maximo ? (fila.cantidad / maximo) * 100 : 0}%` }}
                  />
                </td>
                <td className="numero">{fila.cantidad}</td>
              </tr>
            ))}
          </tbody>
        </Tabla>
      )}
    </section>
  )
}
