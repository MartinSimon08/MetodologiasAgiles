import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Cargando } from '../../components/Cargando'
import { EstadoVacio } from '../../components/EstadoVacio'
import { Tabla } from '../../components/Tabla'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { errorMessage } from '../../lib/api'
import { obtenerReporteTareasFrecuentes } from './api'
import { ReportesNav } from './ReportesNav'
import { Buscador } from '../../components/Buscador'
import { Paginacion } from '../../components/Paginacion'
import { paginarLocal, usePorPagina } from '../../lib/paginacion'
import { coincide } from '../../lib/texto'

export function ReporteTareasFrecuentesPage() {
  const reporte = useQuery({
    queryKey: ['reporte-tareas-frecuentes'],
    queryFn: obtenerReporteTareasFrecuentes,
  })

  const [busqueda, setBusqueda] = useState('')
  const [numeroPagina, setNumeroPagina] = useState(1)
  const [porPagina, setPorPagina] = usePorPagina()

  const maximo = reporte.data?.tareas[0]?.cantidad ?? 0
  const ranking = (reporte.data?.tareas ?? []).map((fila, indice) => ({ fila, puesto: indice + 1 }))
  const filtradas = ranking.filter(({ fila }) => coincide(busqueda, fila.descripcion))
  const pagina = paginarLocal(filtradas, numeroPagina, porPagina)

  return (
    <section className="reportes">
      <EncabezadoPagina
        titulo="Tareas más frecuentes"
        bajada="Cuántas veces se realizó cada tarea o servicio, de más a menos frecuente."
      />
      <ReportesNav />

      {reporte.data && reporte.data.tareas.length > 0 && (
        <Buscador
          etiqueta="Buscar tarea"
          placeholder="Descripción de la tarea"
          valor={busqueda}
          onCambiar={(valor) => {
            setBusqueda(valor)
            setNumeroPagina(1)
          }}
        />
      )}

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

      {reporte.data && reporte.data.tareas.length > 0 && filtradas.length === 0 && (
        <EstadoVacio busqueda titulo="Sin resultados" descripcion={`No hay tareas que coincidan con “${busqueda.trim()}”.`} />
      )}

      {filtradas.length > 0 && (
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
            {pagina.items.map(({ fila, puesto }) => (
              <tr key={fila.descripcion}>
                <td className="numero">{puesto}</td>
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

      {filtradas.length > 0 && (
        <Paginacion
          meta={pagina.meta}
          onCambiar={setNumeroPagina}
          porPagina={porPagina}
          onCambiarPorPagina={(valor) => {
            setPorPagina(valor)
            setNumeroPagina(1)
          }}
        />
      )}
    </section>
  )
}
