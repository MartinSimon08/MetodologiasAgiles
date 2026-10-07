import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { registrarAdelanto } from './api'

interface Props {
  ordenId: number
  onGuardado: () => void
  onCancelar: () => void
}

const IMPORTE_MAXIMO = '9999999999.99'

export function NuevoAdelantoForm({ ordenId, onGuardado, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [importe, setImporte] = useState('')
  const mutation = useMutation({
    mutationFn: () => registrarAdelanto(ordenId, importe),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adelantos', ordenId] })
      onGuardado()
    },
  })
  const errores = fieldErrors(mutation.error)

  function guardar(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate()
  }

  return (
    <form className="tarjeta formulario" onSubmit={guardar}>
      <h2>Registrar adelanto</h2>
      <label>
        Importe ($)
        <input
          type="number"
          inputMode="decimal"
          min="0.01"
          max={IMPORTE_MAXIMO}
          step="0.01"
          value={importe}
          onChange={(event) => setImporte(event.target.value)}
          required
          autoFocus
          disabled={mutation.isPending}
        />
        <small>Tiene que ser mayor que cero. La orden sigue abierta.</small>
        <ErroresCampo errores={errores.importe} />
      </label>
      <ErroresCampo errores={errores.orden} />
      {mutation.isError && Object.keys(errores).length === 0 && (
        <p className="error" role="alert">
          {errorMessage(mutation.error, 'No se pudo registrar el adelanto.')}
        </p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" disabled={mutation.isPending} onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending}>
          {mutation.isPending ? 'Registrando…' : 'Registrar adelanto'}
        </button>
      </div>
    </form>
  )
}
