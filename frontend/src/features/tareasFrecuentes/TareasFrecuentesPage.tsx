import { useQuery } from '@tanstack/react-query'
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

export function TareasFrecuentesPage() {
  const [creando, setCreando] = useState(false)
  const [aviso, setAviso] = useState<string | null>(null)

  const tareasFrecuentes = useQuery({
    queryKey: ['tareas-frecuentes'],
    queryFn: () => listarTareasFrecuentes(),
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

      {tareasFrecuentes.isPending && <Cargando />}
      {tareasFrecuentes.isError && (
        <p className="error" role="alert">
          {errorMessage(tareasFrecuentes.error, 'No se pudo cargar el catálogo.')}
        </p>
      )}

      {tareasFrecuentes.data?.tareas_frecuentes.length === 0 && (
        <EstadoVacio
          titulo="Todavía no hay tareas frecuentes"
          descripcion="Cargá los trabajos habituales con su precio sugerido para agregarlos rápido a las órdenes."
        />
      )}

      {tareasFrecuentes.data && tareasFrecuentes.data.tareas_frecuentes.length > 0 && (
        <Tabla etiqueta="Tareas frecuentes">
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
    </section>
  )
}
