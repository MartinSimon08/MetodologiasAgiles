import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { errorMessage, fieldErrors } from '../../lib/api'
import { crearTarea } from './api'

interface Props {
  ordenId: number
  onCreada: () => void
  onCancelar: () => void
}

export function NuevaTareaForm({ ordenId, onCreada, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [descripcion, setDescripcion] = useState('')

  const mutation = useMutation({
    mutationFn: () => crearTarea(ordenId, descripcion),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tareas', ordenId] })
      setDescripcion('')
      onCreada()
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate()
  }

  return (
    <form className="tarjeta formulario" onSubmit={handleSubmit}>
      <h2>Nueva tarea</h2>
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

function ErroresCampo({ errores }: { errores?: string[] }) {
  if (!errores?.length) return null
  return <span className="error">{errores.join('. ')}</span>
}
