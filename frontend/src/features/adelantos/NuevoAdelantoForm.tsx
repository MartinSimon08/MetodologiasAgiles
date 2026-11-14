import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { importe as formatearImporte } from '../../lib/formato'
import { MEDIO_PAGO_LABELS, MEDIOS_PAGO, registrarAdelanto, superaSaldo, type MedioPago } from './api'

interface Props {
  ordenId: number
  saldo?: string
  onGuardado: () => void
  onCancelar: () => void
}

const IMPORTE_MAXIMO = '9999999999.99'

export function NuevoAdelantoForm({ ordenId, saldo, onGuardado, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [importe, setImporte] = useState('')
  const [medio, setMedio] = useState<MedioPago>('efectivo')
  const excedeSaldo = saldo !== undefined && superaSaldo(importe, saldo)
  const mutation = useMutation({
    mutationFn: () => registrarAdelanto(ordenId, importe, medio),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['adelantos', ordenId] })
      onGuardado()
    },
  })
  const errores = fieldErrors(mutation.error)

  function guardar(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (excedeSaldo) return
    mutation.mutate()
  }

  return (
    <form className="tarjeta formulario" onSubmit={guardar}>
      <h2>Registrar adelanto</h2>
      <label>
        Importe ($)
        <input
          className={excedeSaldo ? 'invalido' : undefined}
          type="number"
          inputMode="decimal"
          min="0.01"
          max={IMPORTE_MAXIMO}
          step="0.01"
          value={importe}
          onChange={(event) => setImporte(event.target.value)}
          required
          autoFocus
          disabled={mutation.isPending}
          aria-invalid={excedeSaldo}
          aria-describedby={excedeSaldo ? 'adelanto-excede-saldo' : undefined}
        />
        <small>Tiene que ser mayor que cero y no puede superar el monto final de la orden. La orden sigue abierta.</small>
        {excedeSaldo && (
          <span id="adelanto-excede-saldo" className="error" role="alert">
            Este monto supera el saldo pendiente ($ {formatearImporte(saldo)}).
          </span>
        )}
        <ErroresCampo errores={errores.importe} />
      </label>
      <label>
        Medio de pago
        <select
          value={medio}
          onChange={(event) => setMedio(event.target.value as MedioPago)}
          disabled={mutation.isPending}
        >
          {MEDIOS_PAGO.map((opcion) => (
            <option key={opcion} value={opcion}>
              {MEDIO_PAGO_LABELS[opcion]}
            </option>
          ))}
        </select>
        <small>Queda registrado junto al cobro. Puede ser la franquicia del asegurado.</small>
        <ErroresCampo errores={errores.medio} />
      </label>
      <ErroresCampo errores={errores.orden} />
      {mutation.isError && Object.keys(errores).length === 0 && (
        <p className="error" role="alert">
          {errorMessage(mutation.error, 'No se pudo registrar el adelanto.')}
        </p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" disabled={mutation.isPending} onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending || excedeSaldo}>
          {mutation.isPending ? 'Registrando…' : 'Registrar adelanto'}
        </button>
      </div>
    </form>
  )
}
