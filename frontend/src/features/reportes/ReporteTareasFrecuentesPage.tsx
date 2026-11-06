import { useQuery } from '@tanstack/react-query'
import { Cargando } from '../../components/Cargando'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { errorMessage } from '../../lib/api'
import { obtenerReporteTareasFrecuentes } from './api'

export function ReporteTareasFrecuentesPage() {
  const reporte = useQuery({
    queryKey: ['reporte-tareas-frecuentes'],
    queryFn: obtenerReporteTareasFrecuentes,
  })

  const maximo = reporte.data?.tareas[0]?.cantidad ?? 0

  return (
    <section className="reportes">
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
        <p className="estado">Todavía no hay tareas terminadas.</p>
      )}

      {reporte.data && reporte.data.tareas.length > 0 && (
        <ol className="lista lista-frecuencia">
          {reporte.data.tareas.map((fila, indice) => (
            <li key={fila.descripcion} className="tarjeta fila-frecuencia">
              <span className="puesto">{indice + 1}</span>
              <div className="item-datos">
                <strong>{fila.descripcion}</strong>
                <span
                  className="barra-frecuencia"
                  style={{ width: `${maximo ? (fila.cantidad / maximo) * 100 : 0}%` }}
                />
              </div>
              <strong>{fila.cantidad} {fila.cantidad === 1 ? 'vez' : 'veces'}</strong>
            </li>
          ))}
        </ol>
      )}
    </section>
  )
}
