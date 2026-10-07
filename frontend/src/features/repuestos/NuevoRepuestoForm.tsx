import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useMemo, useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { importe } from '../../lib/formato'
import { useDebounce } from '../../lib/useDebounce'
import { agregarRepuesto, previsualizarRepuesto, type RepuestoCatalogo } from './api'
import { CatalogoRepuestos } from './CatalogoRepuestos'

interface Props {
  ordenId: number
  onGuardado: () => void
  onCancelar: () => void
}

export function NuevoRepuestoForm({ ordenId, onGuardado, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [seleccionado, setSeleccionado] = useState<RepuestoCatalogo | null>(null)
  const [descripcion, setDescripcion] = useState('')
  const [cantidad, setCantidad] = useState('1')
  const [costo, setCosto] = useState('')
  const [margen, setMargen] = useState('')
  const [proveedor, setProveedor] = useState('')
  const mutation = useMutation({
    mutationFn: () => agregarRepuesto(ordenId, {
      repuesto_catalogo_id: seleccionado?.id,
      descripcion, cantidad, costo_unitario: costo, margen: margen.trim() || undefined, proveedor,
    }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['repuestos', ordenId] })
      queryClient.invalidateQueries({ queryKey: ['adelantos', ordenId] })
      onGuardado()
    },
  })
  const errores = fieldErrors(mutation.error)
  const datos = useMemo(() => ({
    descripcion, cantidad, costo, margen, catalogoId: seleccionado?.id,
  }), [descripcion, cantidad, costo, margen, seleccionado?.id])
  const borrador = useDebounce(datos)
  const puedeConsultar = borrador.descripcion.trim() !== ''
    && borrador.cantidad.trim() !== ''
    && borrador.costo.trim() !== ''
  const vista = useQuery({
    queryKey: ['repuestos', ordenId, 'vista-previa', borrador],
    queryFn: ({ signal }) => previsualizarRepuesto(ordenId, {
      repuesto_catalogo_id: borrador.catalogoId,
      descripcion: borrador.descripcion,
      cantidad: borrador.cantidad,
      costo_unitario: borrador.costo,
      margen: borrador.margen.trim() || undefined,
    }, signal),
    enabled: puedeConsultar,
    retry: false,
  })
  const erroresVista = fieldErrors(vista.error)

  function seleccionar(repuesto: RepuestoCatalogo) {
    setSeleccionado(repuesto)
    setDescripcion(repuesto.nombre)
    setCosto(repuesto.precio)
    mutation.reset()
  }

  function guardar(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate()
  }

  return (
    <form className="tarjeta formulario" onSubmit={guardar}>
      <h2>Agregar repuesto</h2>
      <fieldset className="campos-repuesto" disabled={mutation.isPending}>
        {seleccionado && <p className="estado" role="status">
          Usando {seleccionado.nombre}. Revisá el costo real de esta compra.
          {' '}<button type="button" className="secundario" onClick={() => {
            setSeleccionado(null)
            setDescripcion('')
            setCosto('')
          }}>Cargar otro repuesto</button>
        </p>}
        <label>
          Descripción
          <input value={descripcion} onChange={(event) => setDescripcion(event.target.value)}
            required maxLength={200} readOnly={seleccionado !== null} />
          <ErroresCampo errores={errores.descripcion} />
        </label>
        {!seleccionado && <CatalogoRepuestos key={descripcion} filtro={descripcion} onSeleccionar={seleccionar} />}
        <label>
          Cantidad comprada
          <input type="number" min="1" max="2147483647" step="1" value={cantidad}
            onChange={(event) => setCantidad(event.target.value)} required />
          <ErroresCampo errores={errores.cantidad} />
        </label>
        <label>
          Costo unitario real ($)
          <input type="number" inputMode="decimal" min="0" max="9999999999.99" step="0.01"
            value={costo} onChange={(event) => setCosto(event.target.value)} required
            aria-describedby="ayuda-costo" />
          <small id="ayuda-costo">Podés ajustar el costo sugerido para esta orden.</small>
          <ErroresCampo errores={errores.costo_unitario} />
        </label>
        <label>
          Margen (%) — opcional
          <input type="number" inputMode="decimal" min="0" max="100" step="0.01" value={margen}
            onChange={(event) => setMargen(event.target.value)} placeholder="Margen por defecto del taller" />
          <ErroresCampo errores={errores.margen} />
        </label>
        <label>
          Proveedor — opcional
          <input value={proveedor} onChange={(event) => setProveedor(event.target.value)} />
        </label>
      </fieldset>
      {puedeConsultar && vista.isSuccess && <p className="resumen-repuesto" role="status">
        <span>Precio al cliente: $ {importe(vista.data.precio_cliente)} · Ganancia: $ {importe(vista.data.ganancia)}</span>
        {borrador.margen.trim() === '' && <small>Con el margen del taller ({importe(vista.data.margen)}%).</small>}
      </p>}
      {puedeConsultar && vista.isFetching && !vista.isSuccess && <p className="estado">Calculando precio…</p>}
      {puedeConsultar && vista.isError && Object.keys(erroresVista).length === 0 && <p className="error" role="alert">
        {errorMessage(vista.error, 'No se pudo calcular el precio.')}
      </p>}
      <ErroresCampo errores={errores.orden} />
      {mutation.isError && Object.keys(errores).length === 0 && <p className="error" role="alert">
        {errorMessage(mutation.error, 'No se pudo agregar el repuesto.')}
      </p>}
      <div className="acciones">
        <button type="button" className="secundario" disabled={mutation.isPending} onClick={onCancelar}>Cancelar</button>
        <button type="submit" disabled={mutation.isPending}>{mutation.isPending ? 'Guardando…' : 'Guardar compra'}</button>
      </div>
    </form>
  )
}
