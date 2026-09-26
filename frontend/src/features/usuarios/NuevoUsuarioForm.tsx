import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { errorMessage, fieldErrors } from '../../lib/api'
import { ROL_LABELS, type Rol } from '../auth/types'
import { crearUsuario, type NuevoUsuario } from './api'

const VACIO: NuevoUsuario = { nombre: '', email: '', rol: 'mecanico', password: '' }

interface Props {
  onCreado: (nombre: string) => void
  onCancelar: () => void
}

export function NuevoUsuarioForm({ onCreado, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [datos, setDatos] = useState<NuevoUsuario>(VACIO)

  const mutation = useMutation({
    mutationFn: crearUsuario,
    onSuccess: (usuario) => {
      queryClient.invalidateQueries({ queryKey: ['usuarios'] })
      setDatos(VACIO)
      onCreado(usuario.nombre)
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0

  function actualizar<K extends keyof NuevoUsuario>(campo: K, valor: NuevoUsuario[K]) {
    setDatos((previo) => ({ ...previo, [campo]: valor }))
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate(datos)
  }

  return (
    <form className="tarjeta formulario" onSubmit={handleSubmit} noValidate>
      <h2>Nuevo usuario</h2>
      <label>
        Nombre
        <input value={datos.nombre} onChange={(e) => actualizar('nombre', e.target.value)} required />
        <ErroresCampo errores={errores.nombre} />
      </label>
      <label>
        Email
        <input
          type="email"
          autoComplete="off"
          value={datos.email}
          onChange={(e) => actualizar('email', e.target.value)}
          required
        />
        <ErroresCampo errores={errores.email} />
      </label>
      <label>
        Rol
        <select value={datos.rol} onChange={(e) => actualizar('rol', e.target.value as Rol)}>
          {Object.entries(ROL_LABELS).map(([valor, etiqueta]) => (
            <option key={valor} value={valor}>
              {etiqueta}
            </option>
          ))}
        </select>
        <ErroresCampo errores={errores.rol} />
      </label>
      <label>
        Contraseña inicial
        <input
          type="password"
          autoComplete="new-password"
          minLength={8}
          value={datos.password}
          onChange={(e) => actualizar('password', e.target.value)}
          required
        />
        <small>Mínimo 8 caracteres. Compartísela a la persona para su primer ingreso.</small>
        <ErroresCampo errores={errores.password} />
      </label>
      {mutation.isError && !hayErroresDeCampo && (
        <p className="error" role="alert">{errorMessage(mutation.error)}</p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending}>
          {mutation.isPending ? 'Creando…' : 'Crear usuario'}
        </button>
      </div>
    </form>
  )
}

function ErroresCampo({ errores }: { errores?: string[] }) {
  if (!errores?.length) return null
  return <span className="error">{errores.join('. ')}</span>
}
