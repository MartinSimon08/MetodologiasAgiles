import { useMutation } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { errorMessage, fieldErrors } from '../../lib/api'
import { resetearPassword } from './api'
import type { UsuarioListado } from './api'

interface Props {
  usuario: UsuarioListado
  onListo: () => void
  onCancelar: () => void
}

export function ResetearPasswordForm({ usuario, onListo, onCancelar }: Props) {
  const [password, setPassword] = useState('')

  const mutation = useMutation({
    mutationFn: (nueva: string) => resetearPassword(usuario.id, nueva),
    onSuccess: onListo,
  })

  const errores = fieldErrors(mutation.error).password

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate(password)
  }

  return (
    <form className="formulario reseteo" onSubmit={handleSubmit}>
      <label>
        Nueva contraseña para {usuario.nombre}
        <input
          type="password"
          autoComplete="new-password"
          minLength={8}
          required
          autoFocus
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
      </label>
      {mutation.isError && (
        <p className="error" role="alert">
          {errores?.join('. ') ?? errorMessage(mutation.error)}
        </p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending}>
          {mutation.isPending ? 'Guardando…' : 'Guardar'}
        </button>
      </div>
    </form>
  )
}
