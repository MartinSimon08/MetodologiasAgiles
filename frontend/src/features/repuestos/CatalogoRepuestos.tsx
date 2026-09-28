import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { importe, listarCatalogo, type RepuestoCatalogo } from './api'

interface Props {
  onSeleccionar?: (repuesto: RepuestoCatalogo) => void
}

export function CatalogoRepuestos({ onSeleccionar }: Props) {
  const [buscar, setBuscar] = useState('')
  const [pagina, setPagina] = useState(1)
  const catalogo = useQuery({
    queryKey: ['repuestos-catalogo', buscar, pagina],
    queryFn: () => listarCatalogo(buscar, pagina),
  })

  return (
    <section className="repuestos">
      <h2>Repuestos frecuentes</h2>
      <label>
        Buscar en el catálogo
        <input type="search" value={buscar} onChange={(event) => {
          setBuscar(event.target.value)
          setPagina(1)
        }} />
      </label>
      {catalogo.isPending && <p className="estado">Cargando catálogo…</p>}
      {catalogo.isError && <p className="error" role="alert">
        {errorMessage(catalogo.error, 'No se pudo cargar el catálogo.')}
      </p>}
      {catalogo.data?.repuestos.length === 0 && <p className="estado">
        {buscar ? 'No hay repuestos que coincidan.' : 'El catálogo se completa al registrar compras en las órdenes.'}
      </p>}
      {catalogo.data && <>
        <ul className="lista">
          {catalogo.data.repuestos.map((repuesto) => (
            <li key={repuesto.id} className="tarjeta fila-item">
              <div className="item-datos">
                <strong>{repuesto.nombre}</strong>
                <span>Último costo unitario: $ {importe(repuesto.ultimo_costo)}</span>
              </div>
              {onSeleccionar && <button type="button" className="secundario"
                onClick={() => onSeleccionar(repuesto)} aria-label={`Usar ${repuesto.nombre}`}>
                Usar
              </button>}
            </li>
          ))}
        </ul>
        <Paginacion meta={catalogo.data.meta} cargando={catalogo.isFetching} onCambiar={setPagina} />
      </>}
    </section>
  )
}
