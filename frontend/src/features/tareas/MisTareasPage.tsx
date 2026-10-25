import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { errorMessage } from '../../lib/api'
import { fechaHora } from '../../lib/formato'
import { describirVehiculo } from '../ordenes/types'
import { agregarNotaTarea, completarTarea, liberarTarea, listarTareasMecanico, tomarTarea } from './api'
import { NotasTarea } from './NotasTarea'
import type { TareaMecanico } from './types'

const ACTUALIZACION_MS = 30 * 1000

export function MisTareasPage() {
  const queryClient = useQueryClient()
  const [error, setError] = useState<string | null>(null)
  const [agregandoNotaId, setAgregandoNotaId] = useState<number | null>(null)
  const [notaTexto, setNotaTexto] = useState('')

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
  const agregarNota = useMutation({
    mutationFn: ({ id, contenido }: { id: number; contenido: string }) => agregarNotaTarea(id, contenido),
    onSuccess: () => {
      setAgregandoNotaId(null)
      setNotaTexto('')
    },
    onSettled: invalidar,
    onError: (err: unknown) => setError(errorMessage(err, 'No se pudo agregar la nota.')),
  })

  const ocupado = tomar.isPending || completar.isPending || liberar.isPending

  function ejecutar(accion: (id: number) => void, id: number) {
    setError(null)
    accion(id)
  }

  function empezarNota(id: number) {
    setError(null)
    setAgregandoNotaId(id)
    setNotaTexto('')
  }

  function confirmarNota(id: number) {
    if (!notaTexto.trim()) return
    setError(null)
    agregarNota.mutate({ id, contenido: notaTexto })
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
        {tarea.terminada_en && <span>Terminada a las {fechaHora(tarea.terminada_en)}</span>}
        <NotasTarea notas={tarea.notas} />
        {agregandoNotaId === tarea.id ? (
          <div className="formulario">
            <textarea
              rows={2}
              autoFocus
              placeholder="Lo que encontraste o lo que queda pendiente…"
              value={notaTexto}
              onChange={(e) => setNotaTexto(e.target.value)}
            />
            <div className="acciones">
              <button
                type="button"
                className="secundario"
                disabled={agregarNota.isPending}
                onClick={() => setAgregandoNotaId(null)}
              >
                Cancelar
              </button>
              <button type="button" disabled={agregarNota.isPending} onClick={() => confirmarNota(tarea.id)}>
                Guardar nota
              </button>
            </div>
          </div>
        ) : (
          <button className="secundario" onClick={() => empezarNota(tarea.id)}>
            Agregar nota
          </button>
        )}
      </div>
    )
  }

  return (
    <section className="mis-tareas">
      <EncabezadoPagina titulo="Mis tareas" bajada="Tus trabajos en curso y los disponibles para tomar." />

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

          <h2>Terminadas hoy</h2>
          {tareas.data.terminadas_hoy.length === 0 ? (
            <p className="estado">Todavía no terminaste ninguna tarea hoy.</p>
          ) : (
            <ul className="lista">
              {tareas.data.terminadas_hoy.map((tarea) => (
                <li key={tarea.id} className="tarjeta tarea-movil">
                  {datosTarea(tarea)}
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
