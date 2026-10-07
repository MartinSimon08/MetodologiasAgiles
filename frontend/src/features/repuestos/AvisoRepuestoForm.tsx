import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { avisarRepuesto } from './api'

interface Props {
  ordenId: number
  onGuardado: () => void
  onCancelar: () => void
}

export function AvisoRepuestoForm({ ordenId, onGuardado, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [descripcion, setDescripcion] = useState('')
  const [cantidad, setCantidad] = useState('1')
  const mutation = useMutation({
    mutationFn: () => avisarRepuesto(ordenId, { descripcion, cantidad }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['repuestos', ordenId] })
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
      <h2>Avisar repuesto usado</h2>
      <fieldset disabled={mutation.isPending}>
        <label>
          Descripción
          <input value={descripcion} onChange={(event) => setDescripcion(event.target.value)}
            required maxLength={200} autoFocus />
          <ErroresCampo errores={errores.descripcion} />
        </label>
        <label>
          Cantidad
          <input type="number" min="1" max="2147483647" step="1" value={cantidad}
            onChange={(event) => setCantidad(event.target.value)} required />
          <ErroresCampo errores={errores.cantidad} />
        </label>
        <small>Administración va a cargar el costo y calcular el precio al cliente.</small>
      </fieldset>
      <ErroresCampo errores={errores.orden} />
      {mutation.isError && Object.keys(errores).length === 0 && <p className="error" role="alert">
        {errorMessage(mutation.error, 'No se pudo avisar el repuesto.')}
      </p>}
      <div className="acciones">
        <button type="button" className="secundario" disabled={mutation.isPending} onClick={onCancelar}>Cancelar</button>
        <button type="submit" disabled={mutation.isPending}>{mutation.isPending ? 'Guardando…' : 'Avisar repuesto'}</button>
      </div>
    </form>
  )
}
