import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { importe } from '../../lib/formato'
import { listarRepuestos } from './api'
import { NuevoRepuestoForm } from './NuevoRepuestoForm'

export function RepuestosPanel({ ordenId, ordenAbierta }: { ordenId: number; ordenAbierta: boolean }) {
  const [creando, setCreando] = useState(false)
  const [pagina, setPagina] = useState(1)
  const [aviso, setAviso] = useState(false)
  const repuestos = useQuery({
    queryKey: ['repuestos', ordenId, pagina],
    queryFn: () => listarRepuestos(ordenId, pagina),
  })

  return (
    <section className="repuestos">
      <header className="encabezado">
        <h2>Repuestos comprados</h2>
        {ordenAbierta && !creando && <button onClick={() => {
          setAviso(false)
          setCreando(true)
        }}>Agregar repuesto</button>}
      </header>
      {aviso && <p className="aviso" role="status">Repuesto agregado a la orden.</p>}
      {creando && ordenAbierta && <NuevoRepuestoForm ordenId={ordenId} onCancelar={() => setCreando(false)}
        onGuardado={() => {
          setCreando(false)
          setPagina(1)
          setAviso(true)
        }} />}
      {repuestos.isPending && <p className="estado">Cargando repuestos…</p>}
      {repuestos.isError && <p className="error" role="alert">
        {errorMessage(repuestos.error, 'No se pudieron cargar los repuestos.')}
      </p>}
      {repuestos.data?.repuestos.length === 0 && <p className="estado">Todavía no hay compras registradas en esta orden.</p>}
      {repuestos.data && <>
        <ul className="lista">
          {repuestos.data.repuestos.map((repuesto) => <li key={repuesto.id} className="tarjeta item-datos">
            <strong>{repuesto.descripcion}</strong>
            <span>{repuesto.cantidad} × $ {importe(repuesto.costo_unitario)} · Margen: {importe(repuesto.margen)}%</span>
            <span>Precio al cliente: $ {importe(repuesto.precio_cliente)} · Ganancia: $ {importe(repuesto.ganancia)}</span>
          </li>)}
        </ul>
        <Paginacion meta={repuestos.data.meta} cargando={repuestos.isFetching} onCambiar={setPagina} />
      </>}
    </section>
  )
}
