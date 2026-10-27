import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { BotonNuevo } from '../../components/BotonNuevo'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { importe } from '../../lib/formato'
import { useAuth } from '../auth/AuthContext'
import {
  actualizarPrecioTarea,
  aprobarTarea,
  completarTarea,
  liberarTarea,
  listarTareas,
  rechazarTarea,
  tomarTarea,
} from './api'
import { NotasTarea } from './NotasTarea'
import { NuevaTareaForm } from './NuevaTareaForm'
import { APROBACION_TAREA_LABELS, ESTADO_TAREA_LABELS } from './types'
import { Cargando } from '../../components/Cargando'

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
  const [editandoPrecioId, setEditandoPrecioId] = useState<number | null>(null)
  const [precioEditado, setPrecioEditado] = useState('')
  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)

  const tareas = useQuery({
    queryKey: ['tareas', ordenId, pagina],
    queryFn: () => listarTareas(ordenId, pagina),
    placeholderData: keepPreviousData,
  })

  const invalidar = () => {
    queryClient.invalidateQueries({ queryKey: ['tareas', ordenId] })
    queryClient.invalidateQueries({ queryKey: ['total-parcial', ordenId] })
  }

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
  const actualizarPrecio = useMutation({
    mutationFn: ({ id, precio }: { id: number; precio: string }) => actualizarPrecioTarea(id, precio),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adelantos', ordenId] })
      setEditandoPrecioId(null)
    },
    onSettled: invalidar,
    onError: (err: unknown) => setError(errorMessage(err, 'No se pudo actualizar el precio.')),
  })
  const aprobar = useMutation({
    mutationFn: aprobarTarea,
    onSettled: invalidar,
    onError: (err: unknown) => setError(errorMessage(err, 'No se pudo aprobar la tarea.')),
  })
  const rechazar = useMutation({
    mutationFn: rechazarTarea,
    onSettled: invalidar,
    onError: (err: unknown) => setError(errorMessage(err, 'No se pudo rechazar la tarea.')),
  })

  function irAPagina(nueva: number) {
    setSearchParams(nueva === 1 ? {} : { pagina: String(nueva) })
  }

  function empezarEdicionPrecio(tarea: { id: number; precio?: number | null }) {
    setError(null)
    setEditandoPrecioId(tarea.id)
    setPrecioEditado(tarea.precio != null ? String(tarea.precio) : '')
  }

  function confirmarPrecio(id: number) {
    setError(null)
    actualizarPrecio.mutate({ id, precio: precioEditado })
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
          <BotonNuevo
            onClick={() => {
              setError(null)
              setCreando(true)
            }}
          >
            Nueva tarea
          </BotonNuevo>
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

      {tareas.isPending && <Cargando />}
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
                {esAdministrador && editandoPrecioId === tarea.id ? (
                  <span className="acciones">
                    <input
                      type="number"
                      min="0"
                      step="0.01"
                      inputMode="decimal"
                      autoFocus
                      value={precioEditado}
                      onChange={(e) => setPrecioEditado(e.target.value)}
                    />
                    <button
                      className="secundario"
                      disabled={actualizarPrecio.isPending}
                      onClick={() => setEditandoPrecioId(null)}
                    >
                      Cancelar
                    </button>
                    <button disabled={actualizarPrecio.isPending} onClick={() => confirmarPrecio(tarea.id)}>
                      Guardar
                    </button>
                  </span>
                ) : (
                  esAdministrador && (
                    <span>
                      {tarea.precio != null ? `$ ${importe(tarea.precio)}` : 'Sin precio'}
                      {ordenAbierta && (
                        <button className="secundario" onClick={() => empezarEdicionPrecio(tarea)}>
                          Editar precio
                        </button>
                      )}
                    </span>
                  )
                )}
                <NotasTarea notas={tarea.notas} />
              </div>
              <span className={`insignia insignia-${tarea.estado}`}>
                {ESTADO_TAREA_LABELS[tarea.estado]}
              </span>
              <span className={`insignia insignia-${tarea.aprobacion}`}>
                {APROBACION_TAREA_LABELS[tarea.aprobacion]}
              </span>
              {esAdministrador && ordenAbierta && (
                <span className="acciones">
                  {tarea.aprobacion !== 'aprobada' && (
                    <button
                      className="secundario"
                      disabled={aprobar.isPending}
                      onClick={() => {
                        setError(null)
                        aprobar.mutate(tarea.id)
                      }}
                    >
                      Aprobar
                    </button>
                  )}
                  {tarea.aprobacion !== 'rechazada' && (
                    <button
                      className="secundario"
                      disabled={rechazar.isPending}
                      onClick={() => {
                        setError(null)
                        rechazar.mutate(tarea.id)
                      }}
                    >
                      Rechazar
                    </button>
                  )}
                </span>
              )}
              {esMecanico && ordenAbierta && tarea.estado === 'pendiente' && tarea.aprobacion !== 'rechazada' && (
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
