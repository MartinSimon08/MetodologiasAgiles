import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { useAuth } from '../auth/AuthContext'
import { completarTarea, liberarTarea, listarTareas, tomarTarea } from './api'
import { NuevaTareaForm } from './NuevaTareaForm'
import { ESTADO_TAREA_LABELS } from './types'

interface Props {
  ordenId: number
  ordenAbierta: boolean
}

export function TareasPanel({ ordenId, ordenAbierta }: Props) {
  const { usuario } = useAuth()
  const queryClient = useQueryClient()
  const esMecanico = usuario?.rol === 'mecanico'
  const esAdministrador = usuario?.rol === 'administrador'

  const [creando, setCreando] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)

  const tareas = useQuery({
    queryKey: ['tareas', ordenId, pagina],
    queryFn: () => listarTareas(ordenId, pagina),
    placeholderData: keepPreviousData,
  })

  const invalidar = () => queryClient.invalidateQueries({ queryKey: ['tareas', ordenId] })

  const tomar = useMutation({
    mutationFn: tomarTarea,
    onSettled: invalidar,
    onError: (err: unknown) => setError(errorMessage(err, 'No se pudo tomar la tarea.')),
  })
  const completar = useMutation({
    mutationFn: completarTarea,
    onSettled: invalidar,
    onError: (err: unknown) => setError(errorMessage(err, 'No se pudo completar la tarea.')),
  })
  const liberar = useMutation({
    mutationFn: liberarTarea,
    onSettled: invalidar,
    onError: (err: unknown) => setError(errorMessage(err, 'No se pudo liberar la tarea.')),
  })

  function irAPagina(nueva: number) {
    setSearchParams(nueva === 1 ? {} : { pagina: String(nueva) })
  }

  function responsable(mecanico: { id: number; nombre: string } | null) {
    if (mecanico === null) return 'Sin tomar'
    if (mecanico.id === usuario?.id) return 'Tomada por vos'
    return `Tomada por ${mecanico.nombre}`
  }

  return (
    <section className="tareas">
      <header className="encabezado">
        <h2>Tareas</h2>
        {esAdministrador && ordenAbierta && !creando && (
          <button
            onClick={() => {
              setError(null)
              setCreando(true)
            }}
          >
            Nueva tarea
          </button>
        )}
      </header>

      {error && (
        <p className="error" role="alert">
          {error}
        </p>
      )}

      {creando && (
        <NuevaTareaForm
          ordenId={ordenId}
          onCreada={() => setCreando(false)}
          onCancelar={() => setCreando(false)}
        />
      )}

      {tareas.isPending && <p className="estado">Cargando tareas…</p>}
      {tareas.isError && (
        <p className="error" role="alert">
          {errorMessage(tareas.error, 'No se pudieron cargar las tareas.')}
        </p>
      )}

      {tareas.data && tareas.data.tareas.length === 0 && (
        <p className="estado">Todavía no hay tareas cargadas en esta orden.</p>
      )}

      {tareas.data && (
        <ul className="lista" aria-busy={tareas.isPlaceholderData}>
          {tareas.data.tareas.map((tarea) => (
            <li key={tarea.id} className="tarjeta fila-item">
              <div className="item-datos">
                <strong>{tarea.descripcion}</strong>
                <span>{responsable(tarea.mecanico)}</span>
                {tarea.precio != null && <span>$ {tarea.precio}</span>}
              </div>
              <span className={`insignia insignia-${tarea.estado}`}>
                {ESTADO_TAREA_LABELS[tarea.estado]}
              </span>
              {esMecanico && tarea.estado === 'pendiente' && (
                <button
                  className="secundario"
                  disabled={tomar.isPending}
                  onClick={() => {
                    setError(null)
                    tomar.mutate(tarea.id)
                  }}
                >
                  Tomar
                </button>
              )}
              {esMecanico && tarea.estado === 'en_curso' && tarea.mecanico_id === usuario?.id && (
                <div className="acciones">
                  <button
                    className="secundario"
                    disabled={liberar.isPending}
                    onClick={() => {
                      setError(null)
                      liberar.mutate(tarea.id)
                    }}
                  >
                    Liberar
                  </button>
                  <button
                    disabled={completar.isPending}
                    onClick={() => {
                      setError(null)
                      completar.mutate(tarea.id)
                    }}
                  >
                    Completar
                  </button>
                </div>
              )}
            </li>
          ))}
        </ul>
      )}

      {tareas.data && (
        <Paginacion meta={tareas.data.meta} cargando={tareas.isPlaceholderData} onCambiar={irAPagina} />
      )}
    </section>
  )
}
