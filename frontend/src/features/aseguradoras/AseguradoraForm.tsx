import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { guardarAseguradora, type Aseguradora, type DatosAseguradora } from './api'

interface Props {
  aseguradora?: Aseguradora
  onGuardada: (aseguradora: Aseguradora) => void
  onCancelar: () => void
}

export function AseguradoraForm({ aseguradora, onGuardada, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [datos, setDatos] = useState<DatosAseguradora>({
    nombre: aseguradora?.nombre ?? '',
    telefono: aseguradora?.telefono ?? '',
    email: aseguradora?.email ?? '',
  })

  const mutation = useMutation({
    mutationFn: () => guardarAseguradora(datos, aseguradora?.id),
    onSuccess: (guardada) => {
      queryClient.invalidateQueries({ queryKey: ['aseguradoras'] })
      onGuardada(guardada)
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0

  function actualizar(campo: keyof DatosAseguradora, valor: string) {
    setDatos((previo) => ({ ...previo, [campo]: valor }))
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate()
  }

  return (
    <form className="tarjeta formulario" onSubmit={handleSubmit} noValidate>
      <h2>{aseguradora ? 'Editar aseguradora' : 'Nueva aseguradora'}</h2>
      <label>
        Nombre
        <input
          autoFocus
          autoComplete="off"
          value={datos.nombre}
          onChange={(e) => actualizar('nombre', e.target.value)}
          required
          maxLength={200}
        />
        <ErroresCampo errores={errores.nombre} />
      </label>
      <label>
        Teléfono de contacto (opcional)
        <input
          type="tel"
          inputMode="tel"
          autoComplete="off"
          value={datos.telefono}
          onChange={(e) => actualizar('telefono', e.target.value)}
        />
        <ErroresCampo errores={errores.telefono} />
      </label>
      <label>
        Email de contacto (opcional)
        <input
          type="email"
          autoComplete="off"
          value={datos.email}
          onChange={(e) => actualizar('email', e.target.value)}
        />
        <ErroresCampo errores={errores.email} />
      </label>
      {mutation.isError && !hayErroresDeCampo && (
        <p className="error" role="alert">{errorMessage(mutation.error, 'No se pudo guardar la aseguradora.')}</p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" disabled={mutation.isPending} onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending}>
          {mutation.isPending ? 'Guardando…' : 'Guardar aseguradora'}
        </button>
      </div>
    </form>
  )
}
