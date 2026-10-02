import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { errorMessage } from '../../lib/api'
import { describirVehiculo } from '../ordenes/types'
import { completarTarea, liberarTarea, listarTareasMecanico, tomarTarea } from './api'
import type { TareaMecanico } from './types'

const ACTUALIZACION_MS = 30 * 1000

export function MisTareasPage() {
  const queryClient = useQueryClient()
  const [error, setError] = useState<string | null>(null)

  const tareas = useQuery({
    queryKey: ['tareas-mecanico'],
    queryFn: listarTareasMecanico,
    refetchInterval: ACTUALIZACION_MS,
    refetchOnWindowFocus: true,
  })

  const invalidar = () => queryClient.invalidateQueries({ queryKey: ['tareas-mecanico'] })

  const tomar = useMutation({
    mutationFn: tomarTarea,
    onSettled: invalidar,
    onError: (err: unknown) =>
      setError(errorMessage(err, 'No se pudo tomar la tarea. Puede que otro mecánico ya la haya tomado.')),
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

  const ocupado = tomar.isPending || completar.isPending || liberar.isPending

  function ejecutar(accion: (id: number) => void, id: number) {
    setError(null)
    accion(id)
  }

  function datosTarea(tarea: TareaMecanico) {
    return (
      <div className="item-datos">
        <strong>{tarea.descripcion}</strong>
        <span>
          <Link to={`/ordenes/${tarea.orden.id}`}>Orden #{tarea.orden.id}</Link> ·{' '}
          {describirVehiculo(tarea.orden.vehiculo)}
        </span>
        <span>{tarea.orden.cliente}</span>
      </div>
    )
  }

  return (
    <section className="mis-tareas">
      <h1>Mis tareas</h1>

      {error && (
        <p className="error" role="alert">
          {error}
        </p>
      )}

      {tareas.isPending && <p className="estado">Cargando tareas…</p>}
      {tareas.isError && (
        <p className="error" role="alert">
          {errorMessage(tareas.error, 'No se pudieron cargar las tareas.')}
        </p>
      )}

      {tareas.data && (
        <>
          <h2>En curso</h2>
          {tareas.data.mias.length === 0 ? (
            <p className="estado">No tenés tareas en curso. Tomá una de las disponibles.</p>
          ) : (
            <ul className="lista">
              {tareas.data.mias.map((tarea) => (
                <li key={tarea.id} className="tarjeta tarea-movil">
                  {datosTarea(tarea)}
                  <div className="acciones">
                    <button
                      className="secundario"
                      disabled={ocupado}
                      onClick={() => ejecutar(liberar.mutate, tarea.id)}
                    >
                      Liberar
                    </button>
                    <button disabled={ocupado} onClick={() => ejecutar(completar.mutate, tarea.id)}>
                      Completar
                    </button>
                  </div>
                </li>
              ))}
            </ul>
          )}

          <h2>Disponibles</h2>
          {tareas.data.disponibles.length === 0 ? (
            <p className="estado">No hay tareas disponibles por ahora.</p>
          ) : (
            <ul className="lista">
              {tareas.data.disponibles.map((tarea) => (
                <li key={tarea.id} className="tarjeta tarea-movil">
                  {datosTarea(tarea)}
                  <div className="acciones">
                    <button disabled={ocupado} onClick={() => ejecutar(tomar.mutate, tarea.id)}>
                      Tomar
                    </button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </>
      )}
    </section>
  )
}
