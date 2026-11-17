import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { BotonNuevo } from '../../components/BotonNuevo'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { errorMessage } from '../../lib/api'
import { importe } from '../../lib/formato'
import { listarTareasFrecuentes } from './api'
import { NuevaTareaFrecuenteForm } from './NuevaTareaFrecuenteForm'
import { Cargando } from '../../components/Cargando'
import { EstadoVacio } from '../../components/EstadoVacio'
import { Tabla } from '../../components/Tabla'
import { Buscador } from '../../components/Buscador'
import { Paginacion } from '../../components/Paginacion'
import { usePorPagina } from '../../lib/paginacion'
import { useDebounce } from '../../lib/useDebounce'

export function TareasFrecuentesPage() {
  const [creando, setCreando] = useState(false)
  const [aviso, setAviso] = useState<string | null>(null)

  const [busqueda, setBusqueda] = useState('')
  const [pagina, setPagina] = useState(1)
  const [porPagina, setPorPagina] = usePorPagina()
  const q = useDebounce(busqueda.trim())

  const tareasFrecuentes = useQuery({
    queryKey: ['tareas-frecuentes', 'pagina', pagina, porPagina, q],
    queryFn: () => listarTareasFrecuentes(pagina, porPagina, q),
    placeholderData: keepPreviousData,
  })

  return (
    <section className="tareas-frecuentes">
      <EncabezadoPagina
        titulo="Catálogo de tareas frecuentes"
        bajada="Trabajos habituales con su precio sugerido para cargarlos más rápido."
      >
        {!creando && (
          <BotonNuevo
            onClick={() => {
              setAviso(null)
              setCreando(true)
            }}
          >
            Nueva tarea frecuente
          </BotonNuevo>
        )}
      </EncabezadoPagina>

      {aviso && (
        <p className="aviso" role="status">
          {aviso}
        </p>
      )}

      {creando && (
        <NuevaTareaFrecuenteForm
          onCreada={(descripcion) => {
            setCreando(false)
            setAviso(`Se agregó "${descripcion}" al catálogo.`)
          }}
          onCancelar={() => setCreando(false)}
        />
      )}

      <Buscador
        etiqueta="Buscar tarea frecuente"
        placeholder="Descripción de la tarea"
        valor={busqueda}
        onCambiar={(valor) => {
          setBusqueda(valor)
          setPagina(1)
        }}
      />

      {tareasFrecuentes.isPending && <Cargando />}
      {tareasFrecuentes.isError && (
        <p className="error" role="alert">
          {errorMessage(tareasFrecuentes.error, 'No se pudo cargar el catálogo.')}
        </p>
      )}

      {tareasFrecuentes.data?.tareas_frecuentes.length === 0 && q && (
        <EstadoVacio busqueda titulo="Sin resultados" descripcion={`No hay tareas frecuentes que coincidan con “${q}”.`} />
      )}

      {tareasFrecuentes.data?.tareas_frecuentes.length === 0 && !q && (
        <EstadoVacio
          titulo="Todavía no hay tareas frecuentes"
          descripcion="Cargá los trabajos habituales con su precio sugerido para agregarlos rápido a las órdenes."
        />
      )}

      {tareasFrecuentes.data && tareasFrecuentes.data.tareas_frecuentes.length > 0 && (
        <Tabla etiqueta="Tareas frecuentes" ocupada={tareasFrecuentes.isPlaceholderData}>
          <thead>
            <tr>
              <th scope="col">Descripción</th>
              <th scope="col" className="numero">
                Precio sugerido
              </th>
            </tr>
          </thead>
          <tbody>
            {tareasFrecuentes.data.tareas_frecuentes.map((tareaFrecuente) => (
              <tr key={tareaFrecuente.id}>
                <td>{tareaFrecuente.descripcion}</td>
                <td className="numero">$ {importe(tareaFrecuente.precio_sugerido)}</td>
              </tr>
            ))}
          </tbody>
        </Tabla>
      )}

      {tareasFrecuentes.data && (
        <Paginacion
          meta={tareasFrecuentes.data.meta}
          cargando={tareasFrecuentes.isPlaceholderData}
          onCambiar={setPagina}
          porPagina={porPagina}
          onCambiarPorPagina={(valor) => {
            setPorPagina(valor)
            setPagina(1)
          }}
        />
      )}
    </section>
  )
}
