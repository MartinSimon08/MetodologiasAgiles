import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { guardarCatalogo, type RepuestoCatalogo } from './api'

interface Props {
  repuesto?: RepuestoCatalogo
  onGuardado: () => void
  onCancelar: () => void
}

export function RepuestoCatalogoForm({ repuesto, onGuardado, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [nombre, setNombre] = useState(repuesto?.nombre ?? '')
  const [precio, setPrecio] = useState(repuesto?.precio ?? '')
  const mutation = useMutation({
    mutationFn: () => guardarCatalogo({ nombre, precio }, repuesto?.id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['repuestos-catalogo'] })
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
      <h2>{repuesto ? 'Editar repuesto' : 'Nuevo repuesto del catálogo'}</h2>
      <fieldset className="campos-repuesto" disabled={mutation.isPending}>
        <label>
          Nombre
          <input value={nombre} onChange={(event) => setNombre(event.target.value)} required maxLength={200} />
          <ErroresCampo errores={errores.nombre} />
        </label>
        <label>
          Precio de referencia ($)
          <input type="number" inputMode="decimal" min="0" max="9999999999.99" step="0.01"
            value={precio} onChange={(event) => setPrecio(event.target.value)} required />
          <small>Se sugiere como costo unitario al cargar el repuesto en una orden. El margen se aplica en la orden.</small>
          <ErroresCampo errores={errores.precio} />
        </label>
      </fieldset>
      {mutation.isError && Object.keys(errores).length === 0 && <p className="error" role="alert">
        {errorMessage(mutation.error, 'No se pudo guardar el repuesto en el catálogo.')}
      </p>}
      <div className="acciones">
        <button type="button" className="secundario" disabled={mutation.isPending} onClick={onCancelar}>Cancelar</button>
        <button type="submit" disabled={mutation.isPending}>{mutation.isPending ? 'Guardando…' : 'Guardar repuesto'}</button>
      </div>
    </form>
  )
}
