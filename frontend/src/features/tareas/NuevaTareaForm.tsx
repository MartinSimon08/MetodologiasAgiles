import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { listarTareasFrecuentes } from '../tareasFrecuentes/api'
import { crearTarea } from './api'

interface Props {
  ordenId: number
  onCreada: () => void
  onCancelar: () => void
}

const SIN_CATALOGO = ''

export function NuevaTareaForm({ ordenId, onCreada, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [descripcion, setDescripcion] = useState('')
  const [precio, setPrecio] = useState('')
  const [catalogoId, setCatalogoId] = useState(SIN_CATALOGO)

  const tareasFrecuentes = useQuery({
    queryKey: ['tareas-frecuentes'],
    queryFn: () => listarTareasFrecuentes(),
  })

  const mutation = useMutation({
    mutationFn: () => crearTarea(ordenId, descripcion, precio),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tareas', ordenId] })
      setDescripcion('')
      setPrecio('')
      setCatalogoId(SIN_CATALOGO)
      onCreada()
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0

  function elegirDelCatalogo(id: string) {
    setCatalogoId(id)
    const tareaFrecuente = tareasFrecuentes.data?.tareas_frecuentes.find((t) => String(t.id) === id)
    if (tareaFrecuente) {
      setDescripcion(tareaFrecuente.descripcion)
      setPrecio(String(tareaFrecuente.precio_sugerido))
    }
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate()
  }

  return (
    <form className="tarjeta formulario" onSubmit={handleSubmit}>
      <h2>Nueva tarea</h2>
      {!!tareasFrecuentes.data?.tareas_frecuentes.length && (
        <label>
          Tarea del catálogo (opcional)
          <select value={catalogoId} onChange={(e) => elegirDelCatalogo(e.target.value)}>
            <option value={SIN_CATALOGO}>Escribir manualmente…</option>
            {tareasFrecuentes.data.tareas_frecuentes.map((tareaFrecuente) => (
              <option key={tareaFrecuente.id} value={tareaFrecuente.id}>
                {tareaFrecuente.descripcion} (sugerido $ {tareaFrecuente.precio_sugerido})
              </option>
            ))}
          </select>
        </label>
      )}
      <label>
        Descripción
        <input
          value={descripcion}
          onChange={(e) => setDescripcion(e.target.value)}
          required
          autoFocus
        />
        <ErroresCampo errores={errores.descripcion} />
      </label>
      <label>
        Precio de mano de obra (opcional)
        <input
          type="number"
          min="0"
          step="0.01"
          inputMode="decimal"
          value={precio}
          onChange={(e) => setPrecio(e.target.value)}
        />
        <small>Se completa con el precio sugerido del catálogo, pero se puede editar.</small>
        <ErroresCampo errores={errores.precio} />
      </label>
      {mutation.isError && !hayErroresDeCampo && (
        <p className="error" role="alert">
          {errorMessage(mutation.error)}
        </p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending}>
          {mutation.isPending ? 'Creando…' : 'Crear tarea'}
        </button>
      </div>
    </form>
  )
}
