import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { registrarAjuste, type Repuesto, type TipoAjuste } from './api'

interface Props {
  ordenId: number
  repuesto: Repuesto
  onGuardado: (tipo: TipoAjuste) => void
  onCancelar: () => void
}

const MOTIVO_MAXIMO = 500

export function RegistrarAjusteForm({ ordenId, repuesto, onGuardado, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [tipo, setTipo] = useState<TipoAjuste>('devolucion')
  const [cantidad, setCantidad] = useState('1')
  const [costo, setCosto] = useState(repuesto.costo_unitario ?? '')
  const [motivo, setMotivo] = useState('')
  const unidades = Number(cantidad)
  const excedeCantidad = cantidad !== '' && (
    !Number.isInteger(unidades) || unidades < 1 || unidades > repuesto.cantidad_disponible
  )
  const mutation = useMutation({
    mutationFn: () => registrarAjuste(ordenId, repuesto.id, {
      tipo,
      cantidad,
      costo_unitario: costo,
      motivo,
    }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['repuestos', ordenId] })
      queryClient.invalidateQueries({ queryKey: ['adelantos', ordenId] })
      onGuardado(tipo)
    },
  })
  const errores = fieldErrors(mutation.error)
  const esDevolucion = tipo === 'devolucion'

  function guardar(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (excedeCantidad) return
    mutation.mutate()
  }

  return (
    <form className="tarjeta formulario" onSubmit={guardar}>
      <h2>Devolución o cambio: {repuesto.descripcion}</h2>
      <p className="estado">
        El registro original se conserva. Quedan {repuesto.cantidad_disponible} unidades sin devolver ni cambiar.
      </p>
      <fieldset className="opciones" disabled={mutation.isPending}>
        <legend>Qué pasó</legend>
        <label>
          <input
            type="radio"
            name="tipo-ajuste"
            value="devolucion"
            checked={esDevolucion}
            onChange={() => setTipo('devolucion')}
          />
          Devolución
        </label>
        <label>
          <input
            type="radio"
            name="tipo-ajuste"
            value="cambio"
            checked={!esDevolucion}
            onChange={() => setTipo('cambio')}
          />
          Cambio
        </label>
      </fieldset>
      <ErroresCampo errores={errores.tipo} />
      <label>
        Cantidad
        <input
          type="number"
          inputMode="numeric"
          min="1"
          max={repuesto.cantidad_disponible}
          step="1"
          value={cantidad}
          onChange={(event) => setCantidad(event.target.value)}
          required
          autoFocus
          disabled={mutation.isPending}
          aria-invalid={excedeCantidad}
        />
        <ErroresCampo errores={errores.cantidad} />
        {excedeCantidad && (
          <span className="error" role="alert">
            La cantidad supera las unidades que todavía no se devolvieron ni cambiaron.
          </span>
        )}
      </label>
      <label>
        {esDevolucion ? 'Costo unitario acreditado ($)' : 'Costo unitario del reemplazo ($)'}
        <input
          type="number"
          inputMode="decimal"
          min="0"
          max="9999999999.99"
          step="0.01"
          value={costo}
          onChange={(event) => setCosto(event.target.value)}
          required
          disabled={mutation.isPending}
        />
        <small>
          {esDevolucion
            ? 'Es lo que el proveedor devuelve por cada unidad. El precio al cliente de esas unidades se quita de la orden.'
            : 'Esas unidades siguen en la orden. Su precio al cliente se recalcula con este costo y el margen original.'}
        </small>
        <ErroresCampo errores={errores.costo_unitario} />
      </label>
      <label>
        Motivo
        <textarea
          rows={3}
          maxLength={MOTIVO_MAXIMO}
          value={motivo}
          onChange={(event) => setMotivo(event.target.value)}
          required
          disabled={mutation.isPending}
          placeholder="Qué falló y qué se hizo con el repuesto"
        />
        <ErroresCampo errores={errores.motivo} />
      </label>
      <ErroresCampo errores={errores.orden} />
      <ErroresCampo errores={errores.repuesto} />
      <ErroresCampo errores={errores.base} />
      {mutation.isError && Object.keys(errores).length === 0 && (
        <p className="error" role="alert">
          {errorMessage(mutation.error, 'No se pudo registrar la devolución o el cambio.')}
        </p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" disabled={mutation.isPending} onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending || excedeCantidad}>
          {mutation.isPending ? 'Registrando…' : 'Registrar'}
        </button>
      </div>
    </form>
  )
}
