import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { valorizarRepuesto, type Repuesto } from './api'

interface Props {
  ordenId: number
  repuesto: Repuesto
  onGuardado: () => void
  onCancelar: () => void
}

export function ValorizarRepuestoForm({ ordenId, repuesto, onGuardado, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [costo, setCosto] = useState('')
  const [margen, setMargen] = useState('')
  const mutation = useMutation({
    mutationFn: () => valorizarRepuesto(ordenId, repuesto.id, { costo_unitario: costo, margen: margen || undefined }),
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
      <h2>Cargar costo: {repuesto.descripcion}</h2>
      <fieldset disabled={mutation.isPending}>
        <label>
          Costo unitario real ($)
          <input type="number" inputMode="decimal" min="0" max="9999999999.99" step="0.01"
            value={costo} onChange={(event) => setCosto(event.target.value)} required autoFocus />
          <ErroresCampo errores={errores.costo_unitario} />
        </label>
        <label>
          Margen (%) — opcional
          <input type="number" inputMode="decimal" min="0" max="100" step="0.01" value={margen}
            onChange={(event) => setMargen(event.target.value)} placeholder="Margen por defecto del taller" />
          <ErroresCampo errores={errores.margen} />
        </label>
      </fieldset>
      <ErroresCampo errores={errores.estado} />
      <ErroresCampo errores={errores.orden} />
      {mutation.isError && Object.keys(errores).length === 0 && <p className="error" role="alert">
        {errorMessage(mutation.error, 'No se pudo cargar el costo.')}
      </p>}
      <div className="acciones">
        <button type="button" className="secundario" disabled={mutation.isPending} onClick={onCancelar}>Cancelar</button>
        <button type="submit" disabled={mutation.isPending}>{mutation.isPending ? 'Guardando…' : 'Guardar costo'}</button>
      </div>
    </form>
  )
}
