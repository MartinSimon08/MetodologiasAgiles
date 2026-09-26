import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { registrarCliente, type NuevoCliente } from './api'

const VACIO: NuevoCliente = { nombre: '', telefono: '', email: '' }

interface Props {
  onRegistrado: (nombre: string) => void
  onCancelar: () => void
}

export function NuevoClienteForm({ onRegistrado, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [datos, setDatos] = useState<NuevoCliente>(VACIO)

  const mutation = useMutation({
    mutationFn: registrarCliente,
    onSuccess: (cliente) => {
      queryClient.invalidateQueries({ queryKey: ['clientes'] })
      setDatos(VACIO)
      onRegistrado(cliente.nombre)
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0

  function actualizar(campo: keyof NuevoCliente, valor: string) {
    setDatos((previo) => ({ ...previo, [campo]: valor }))
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate(datos)
  }

  return (
    <form className="tarjeta formulario" onSubmit={handleSubmit} noValidate>
      <h2>Nuevo cliente</h2>
      <label>
        Nombre
        <input
          autoFocus
          autoComplete="off"
          value={datos.nombre}
          onChange={(e) => actualizar('nombre', e.target.value)}
          required
        />
        <ErroresCampo errores={errores.nombre} />
      </label>
      <label>
        Teléfono
        <input
          type="tel"
          inputMode="tel"
          autoComplete="off"
          value={datos.telefono}
          onChange={(e) => actualizar('telefono', e.target.value)}
          required
        />
        <small>Se usa para identificar al cliente, no puede repetirse.</small>
        <ErroresCampo errores={errores.telefono} />
      </label>
      <label>
        Email (opcional)
        <input
          type="email"
          autoComplete="off"
          value={datos.email}
          onChange={(e) => actualizar('email', e.target.value)}
        />
        <ErroresCampo errores={errores.email} />
      </label>
      {mutation.isError && !hayErroresDeCampo && (
        <p className="error" role="alert">{errorMessage(mutation.error)}</p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending}>
          {mutation.isPending ? 'Registrando…' : 'Registrar cliente'}
        </button>
      </div>
    </form>
  )
}
