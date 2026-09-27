import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { crearTareaFrecuente, type NuevaTareaFrecuente } from './api'

const VACIO: NuevaTareaFrecuente = { descripcion: '', precio_sugerido: '' }

interface Props {
  onCreada: (descripcion: string) => void
  onCancelar: () => void
}

export function NuevaTareaFrecuenteForm({ onCreada, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [datos, setDatos] = useState<NuevaTareaFrecuente>(VACIO)

  const mutation = useMutation({
    mutationFn: crearTareaFrecuente,
    onSuccess: (tareaFrecuente) => {
      queryClient.invalidateQueries({ queryKey: ['tareas-frecuentes'] })
      setDatos(VACIO)
      onCreada(tareaFrecuente.descripcion)
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0

  function actualizar(campo: keyof NuevaTareaFrecuente, valor: string) {
    setDatos((previo) => ({ ...previo, [campo]: valor }))
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate(datos)
  }

  return (
    <form className="tarjeta formulario" onSubmit={handleSubmit} noValidate>
      <h2>Nueva tarea frecuente</h2>
      <label>
        Descripción
        <input
          autoFocus
          autoComplete="off"
          value={datos.descripcion}
          onChange={(e) => actualizar('descripcion', e.target.value)}
          required
        />
        <ErroresCampo errores={errores.descripcion} />
      </label>
      <label>
        Precio sugerido
        <input
          type="number"
          min="0.01"
          step="0.01"
          inputMode="decimal"
          value={datos.precio_sugerido}
          onChange={(e) => actualizar('precio_sugerido', e.target.value)}
          required
        />
        <ErroresCampo errores={errores.precio_sugerido} />
      </label>
      {mutation.isError && !hayErroresDeCampo && (
        <p className="error" role="alert">{errorMessage(mutation.error)}</p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending}>
          {mutation.isPending ? 'Creando…' : 'Crear tarea frecuente'}
        </button>
      </div>
    </form>
  )
}
