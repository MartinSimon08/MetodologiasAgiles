import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { VehiculoSelector } from '../vehiculos/VehiculoSelector'
import { abrirOrden } from './api'
import { MOTIVO_LARGO_MAXIMO, type Orden } from './types'

interface Props {
  onAbierta: (orden: Orden) => void
  onCancelar: () => void
}

export function NuevaOrdenForm({ onAbierta, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [vehiculoId, setVehiculoId] = useState<number | null>(null)
  const [motivo, setMotivo] = useState('')

  const mutation = useMutation({
    mutationFn: () => abrirOrden(vehiculoId, motivo),
    onSuccess: (orden) => {
      queryClient.invalidateQueries({ queryKey: ['ordenes'] })
      onAbierta(orden)
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate()
  }

  return (
    <form className="tarjeta formulario nueva-orden" onSubmit={handleSubmit} noValidate>
      <h2>Nueva orden de trabajo</h2>
      <div className="grupo-vehiculo">
        <VehiculoSelector
          etiqueta="Vehículo"
          valor={vehiculoId}
          onCambiar={setVehiculoId}
          errores={errores.vehiculo}
          autoFocus
        />
        <small>
          La orden queda a nombre del dueño del vehículo. Si el vehículo no aparece, registralo primero en{' '}
          <Link to="/vehiculos">Vehículos</Link>.
        </small>
      </div>
      <label>
        Motivo de ingreso
        <textarea
          rows={3}
          maxLength={MOTIVO_LARGO_MAXIMO}
          value={motivo}
          onChange={(e) => setMotivo(e.target.value)}
          required
        />
        <small>Lo que declara el cliente al dejar el vehículo.</small>
        <ErroresCampo errores={errores.motivo} />
      </label>
      {mutation.isError && !hayErroresDeCampo && (
        <p className="error" role="alert">
          {errorMessage(mutation.error)}
        </p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending || vehiculoId === null}>
          {mutation.isPending ? 'Abriendo…' : 'Abrir orden'}
        </button>
      </div>
    </form>
  )
}
