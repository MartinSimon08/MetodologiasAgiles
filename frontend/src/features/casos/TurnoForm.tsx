import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { asignarTurno, hoyIso, type Caso } from './api'

interface Props {
  casoId: number
  numeroSiniestro: string
  fechaActual: string | null
  onListo: (caso: Caso) => void
  onCancelar: () => void
}

export function TurnoForm({ casoId, numeroSiniestro, fechaActual, onListo, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [fecha, setFecha] = useState(fechaActual ?? '')
  const reprogramando = fechaActual !== null

  const mutation = useMutation({
    mutationFn: () => asignarTurno(casoId, fecha),
    onSuccess: async (caso) => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: ['casos'] }),
        queryClient.invalidateQueries({ queryKey: ['turnera'] }),
      ])
      onListo(caso)
    },
  })

  const errores = fieldErrors(mutation.error)

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate()
  }

  return (
    <form className="formulario turno-form" onSubmit={handleSubmit} noValidate>
      <label>
        <span>{reprogramando ? `Nueva fecha para ${numeroSiniestro}` : `Fecha de ingreso de ${numeroSiniestro}`}</span>
        <input
          type="date"
          value={fecha}
          min={hoyIso()}
          onChange={(event) => setFecha(event.target.value)}
          className={errores.fecha_turno ? 'invalido' : undefined}
          aria-invalid={Boolean(errores.fecha_turno)}
          autoFocus
        />
        <ErroresCampo errores={errores.fecha_turno} />
      </label>
      {mutation.isError && !errores.fecha_turno && (
        <p className="error" role="alert">
          {errores.base?.join('. ') ?? errorMessage(mutation.error, 'No se pudo guardar el turno.')}
        </p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending || fecha === '' || fecha === fechaActual}>
          {mutation.isPending ? 'Guardando…' : reprogramando ? 'Reprogramar' : 'Asignar turno'}
        </button>
      </div>
    </form>
  )
}
