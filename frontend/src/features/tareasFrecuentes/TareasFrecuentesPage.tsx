import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { errorMessage } from '../../lib/api'
import { listarTareasFrecuentes } from './api'
import { NuevaTareaFrecuenteForm } from './NuevaTareaFrecuenteForm'

export function TareasFrecuentesPage() {
  const [creando, setCreando] = useState(false)
  const [aviso, setAviso] = useState<string | null>(null)

  const tareasFrecuentes = useQuery({
    queryKey: ['tareas-frecuentes'],
    queryFn: () => listarTareasFrecuentes(),
  })

  return (
    <section className="tareas-frecuentes">
      <header className="encabezado">
        <h1>Catálogo de tareas frecuentes</h1>
        {!creando && (
          <button
            onClick={() => {
              setAviso(null)
              setCreando(true)
            }}
          >
            Nueva tarea frecuente
          </button>
        )}
      </header>

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

      {tareasFrecuentes.isPending && <p className="estado">Cargando catálogo…</p>}
      {tareasFrecuentes.isError && (
        <p className="error" role="alert">
          {errorMessage(tareasFrecuentes.error, 'No se pudo cargar el catálogo.')}
        </p>
      )}

      {tareasFrecuentes.data?.tareas_frecuentes.length === 0 && (
        <p className="estado">Todavía no hay tareas frecuentes cargadas.</p>
      )}

      {tareasFrecuentes.data && tareasFrecuentes.data.tareas_frecuentes.length > 0 && (
        <ul className="lista">
          {tareasFrecuentes.data.tareas_frecuentes.map((tareaFrecuente) => (
            <li key={tareaFrecuente.id} className="tarjeta fila-item">
              <div className="item-datos">
                <strong>{tareaFrecuente.descripcion}</strong>
              </div>
              <span>$ {tareaFrecuente.precio_sugerido}</span>
            </li>
          ))}
        </ul>
      )}
    </section>
  )
}
