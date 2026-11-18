import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { editarCliente, type Cliente } from './api'

interface Props {
  cliente: Cliente
  onTerminar: () => void
}

export function EditarClienteForm({ cliente, onTerminar }: Props) {
  const queryClient = useQueryClient()
  const [datos, setDatos] = useState({ nombre: cliente.nombre, telefono: cliente.telefono, email: cliente.email ?? '' })

  const mutation = useMutation({
    mutationFn: () => editarCliente(cliente.id, datos),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cliente', cliente.id] })
      queryClient.invalidateQueries({ queryKey: ['clientes'] })
      onTerminar()
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate()
  }

  return (
    <form className="tarjeta formulario" onSubmit={handleSubmit} noValidate>
      <h2>Editar cliente</h2>
      <label>
        Nombre
        <input value={datos.nombre} onChange={(e) => setDatos({ ...datos, nombre: e.target.value })} required />
        <ErroresCampo errores={errores.nombre} />
      </label>
      <label>
        Teléfono
        <input
          type="tel"
          inputMode="tel"
          value={datos.telefono}
          onChange={(e) => setDatos({ ...datos, telefono: e.target.value })}
          required
        />
        <small>Si cambia el teléfono, hay que volver a vincular Telegram.</small>
        <ErroresCampo errores={errores.telefono} />
      </label>
      <label>
        Email (opcional)
        <input type="email" value={datos.email} onChange={(e) => setDatos({ ...datos, email: e.target.value })} />
        <ErroresCampo errores={errores.email} />
      </label>
      {mutation.isError && !hayErroresDeCampo && (
        <p className="error" role="alert">{errorMessage(mutation.error)}</p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={onTerminar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending}>
          {mutation.isPending ? 'Guardando…' : 'Guardar cambios'}
        </button>
      </div>
    </form>
  )
}
