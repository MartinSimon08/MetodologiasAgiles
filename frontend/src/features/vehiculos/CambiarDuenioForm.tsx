import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { errorMessage, fieldErrors } from '../../lib/api'
import { ClienteSelector } from '../clientes/ClienteSelector'
import { cambiarDuenio, type Vehiculo } from './api'

interface Props {
  vehiculo: Vehiculo
  onListo: (actualizado: Vehiculo) => void
  onCancelar: () => void
}

export function CambiarDuenioForm({ vehiculo, onListo, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [clienteId, setClienteId] = useState<number | null>(null)

  const mutation = useMutation({
    mutationFn: () => cambiarDuenio(vehiculo.id, clienteId),
    onSuccess: (actualizado) => {
      queryClient.invalidateQueries({ queryKey: ['vehiculos'] })
      onListo(actualizado)
    },
  })

  const errores = fieldErrors(mutation.error)

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate()
  }

  return (
    <form className="formulario cambio-duenio" onSubmit={handleSubmit} noValidate>
      <ClienteSelector
        etiqueta={`Nuevo dueño de ${vehiculo.patente}`}
        valor={clienteId}
        onCambiar={setClienteId}
        excluirId={vehiculo.cliente.id}
        errores={errores.cliente}
        autoFocus
      />
      {mutation.isError && !errores.cliente && (
        <p className="error" role="alert">{errorMessage(mutation.error)}</p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending || clienteId === null}>
          {mutation.isPending ? 'Guardando…' : 'Cambiar dueño'}
        </button>
      </div>
    </form>
  )
}
