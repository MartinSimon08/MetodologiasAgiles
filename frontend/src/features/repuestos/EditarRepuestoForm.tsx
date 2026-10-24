import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useMemo, useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { importe } from '../../lib/formato'
import { useDebounce } from '../../lib/useDebounce'
import { invalidarTotalesOrden } from '../ordenes/totales'
import { editarRepuesto, previsualizarRepuesto, type Repuesto } from './api'

interface Props {
  ordenId: number
  repuesto: Repuesto
  onGuardado: () => void
  onCancelar: () => void
}

export function EditarRepuestoForm({ ordenId, repuesto, onGuardado, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const valorizado = repuesto.estado === 'valorizado'
  const [cantidad, setCantidad] = useState(String(repuesto.cantidad))
  const [costo, setCosto] = useState(repuesto.costo_unitario ?? '')
  const [margen, setMargen] = useState(repuesto.margen ?? '')
  const [proveedor, setProveedor] = useState(repuesto.proveedor ?? '')
  const mutation = useMutation({
    mutationFn: () => editarRepuesto(ordenId, repuesto.id, valorizado
      ? { cantidad, costo_unitario: costo, margen, proveedor }
      : { cantidad, proveedor }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['repuestos', ordenId] })
      invalidarTotalesOrden(queryClient, ordenId)
      onGuardado()
    },
  })
  const errores = fieldErrors(mutation.error)
  const datos = useMemo(() => ({ cantidad, costo, margen }), [cantidad, costo, margen])
  const borrador = useDebounce(datos)
  const puedeConsultar = valorizado
    && borrador.cantidad.trim() !== ''
    && borrador.costo.trim() !== ''
    && borrador.margen.trim() !== ''
  const vista = useQuery({
    queryKey: ['repuestos', ordenId, 'vista-previa-edicion', repuesto.id, borrador],
    queryFn: ({ signal }) => previsualizarRepuesto(ordenId, {
      descripcion: repuesto.descripcion,
      cantidad: borrador.cantidad,
      costo_unitario: borrador.costo,
      margen: borrador.margen,
    }, signal),
    enabled: puedeConsultar,
    retry: false,
  })
  const erroresVista = fieldErrors(vista.error)

  function guardar(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate()
  }

  return (
    <form className="tarjeta formulario" onSubmit={guardar}>
      <h2>Corregir {repuesto.descripcion}</h2>
      <fieldset className="campos-repuesto" disabled={mutation.isPending}>
        <label>
          Cantidad comprada
          <input type="number" min="1" max="2147483647" step="1" value={cantidad}
            onChange={(event) => setCantidad(event.target.value)} required autoFocus />
          <ErroresCampo errores={errores.cantidad} />
        </label>
        {valorizado && <>
          <label>
            Costo unitario real ($)
            <input type="number" inputMode="decimal" min="0" max="9999999999.99" step="0.01"
              value={costo} onChange={(event) => setCosto(event.target.value)} required />
            <ErroresCampo errores={errores.costo_unitario ?? erroresVista.costo_unitario} />
          </label>
          <label>
            Margen (%)
            <input type="number" inputMode="decimal" min="0" max="100" step="0.01" value={margen}
              onChange={(event) => setMargen(event.target.value)} required />
            <ErroresCampo errores={errores.margen ?? erroresVista.margen} />
          </label>
        </>}
        {!valorizado && <p className="estado">El costo se carga aparte, con Cargar costo.</p>}
        <label>
          Proveedor (opcional)
          <input value={proveedor} onChange={(event) => setProveedor(event.target.value)} />
        </label>
      </fieldset>
      {puedeConsultar && vista.isSuccess && <p className="resumen-repuesto" role="status">
        <span>Precio al cliente: $ {importe(vista.data.precio_cliente)} · Ganancia: $ {importe(vista.data.ganancia)}</span>
      </p>}
      {puedeConsultar && vista.isFetching && !vista.isSuccess && <p className="estado">Calculando precio…</p>}
      {puedeConsultar && vista.isError && Object.keys(erroresVista).length === 0 && <p className="error" role="alert">
        {errorMessage(vista.error, 'No se pudo calcular el precio.')}
      </p>}
      <ErroresCampo errores={errores.base} />
      <ErroresCampo errores={errores.orden} />
      <ErroresCampo errores={errores.estado} />
      {mutation.isError && Object.keys(errores).length === 0 && <p className="error" role="alert">
        {errorMessage(mutation.error, 'No se pudo corregir el repuesto.')}
      </p>}
      <div className="acciones">
        <button type="button" className="secundario" disabled={mutation.isPending} onClick={onCancelar}>Cancelar</button>
        <button type="submit" disabled={mutation.isPending}>{mutation.isPending ? 'Guardando…' : 'Guardar corrección'}</button>
      </div>
    </form>
  )
}
