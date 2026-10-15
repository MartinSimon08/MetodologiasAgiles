import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Buscador } from '../../components/Buscador'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { importe } from '../../lib/formato'
import { listarCatalogo, type RepuestoCatalogo } from './api'

interface Props {
  onSeleccionar?: (repuesto: RepuestoCatalogo) => void
  onEditar?: (repuesto: RepuestoCatalogo) => void
  onEliminar?: (repuesto: RepuestoCatalogo) => void
  filtro?: string
}

export function CatalogoRepuestos({ onSeleccionar, onEditar, onEliminar, filtro }: Props) {
  const [busqueda, setBuscar] = useState('')
  const buscar = filtro ?? busqueda
  const [pagina, setPagina] = useState(1)
  const catalogo = useQuery({
    queryKey: ['repuestos-catalogo', buscar, pagina],
    queryFn: () => listarCatalogo(buscar, pagina),
  })

  return (
    <section className="repuestos">
      {onSeleccionar && <h2>Sugerencias del catálogo</h2>}
      {filtro === undefined && <Buscador etiqueta="Buscar en el catálogo" placeholder="Nombre del repuesto"
        valor={buscar} onCambiar={(valor) => {
          setBuscar(valor)
          setPagina(1)
        }} />}
      {catalogo.isPending && <p className="estado">Cargando catálogo…</p>}
      {catalogo.isError && <p className="error" role="alert">
        {errorMessage(catalogo.error, 'No se pudo cargar el catálogo.')}
      </p>}
      {catalogo.data?.repuestos.length === 0 && <p className="vacio">
        {buscar ? 'No hay repuestos que coincidan.' : 'Todavía no hay repuestos cargados en el catálogo.'}
      </p>}
      {catalogo.data && <>
        <ul className="lista">
          {catalogo.data.repuestos.map((repuesto) => (
            <li key={repuesto.id} className="tarjeta fila-item">
              <div className="item-datos">
                <strong>{repuesto.nombre}</strong>
                <span>Precio de referencia: $ {importe(repuesto.precio)}</span>
              </div>
              {(onSeleccionar || onEditar || onEliminar) && <div className="item-acciones">
                {onSeleccionar && <button type="button" className="secundario"
                  onClick={() => onSeleccionar(repuesto)} aria-label={`Usar ${repuesto.nombre}`}>
                  Usar
                </button>}
                {onEditar && <button type="button" className="secundario"
                  onClick={() => onEditar(repuesto)} aria-label={`Editar ${repuesto.nombre}`}>
                  Editar
                </button>}
                {onEliminar && <button type="button" className="secundario peligro"
                  onClick={() => onEliminar(repuesto)} aria-label={`Eliminar ${repuesto.nombre}`}>
                  Eliminar
                </button>}
              </div>}
            </li>
          ))}
        </ul>
        <Paginacion meta={catalogo.data.meta} cargando={catalogo.isFetching} onCambiar={setPagina} />
      </>}
    </section>
  )
}
