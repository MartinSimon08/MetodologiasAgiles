import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { importe } from '../../lib/formato'
import { listarCatalogo, type RepuestoCatalogo } from './api'
import { Cargando } from '../../components/Cargando'
import { EstadoVacio } from '../../components/EstadoVacio'
import { MenuAcciones, type Accion } from '../../components/MenuAcciones'
import { Tabla } from '../../components/Tabla'

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
      {filtro === undefined && <label className="buscador">
        <span>Buscar en el catálogo</span>
        <input type="search" placeholder="Nombre del repuesto" value={buscar} onChange={(event) => {
          setBuscar(event.target.value)
          setPagina(1)
        }} />
      </label>}
      {catalogo.isPending && <Cargando />}
      {catalogo.isError && <p className="error" role="alert">
        {errorMessage(catalogo.error, 'No se pudo cargar el catálogo.')}
      </p>}
      {catalogo.data?.repuestos.length === 0 && (onSeleccionar ? <p className="estado">
        {buscar ? 'No hay repuestos que coincidan.' : 'Todavía no hay repuestos cargados en el catálogo.'}
      </p> : buscar ? (
        <EstadoVacio busqueda titulo="Sin resultados" descripcion="No hay repuestos que coincidan." />
      ) : (
        <EstadoVacio
          titulo="Todavía no hay repuestos en el catálogo"
          descripcion="Cargá repuestos con su precio de referencia para autocompletar las órdenes."
        />
      ))}
      {catalogo.data && !onSeleccionar && catalogo.data.repuestos.length > 0 && <>
        <Tabla etiqueta="Catálogo de repuestos" ocupada={catalogo.isFetching}>
          <thead>
            <tr>
              <th scope="col">Repuesto</th>
              <th scope="col" className="numero">Precio de referencia</th>
              {(onEditar || onEliminar) && <th scope="col" className="acciones-celda">
                <span className="solo-lectores">Acciones</span>
              </th>}
            </tr>
          </thead>
          <tbody>
            {catalogo.data.repuestos.map((repuesto) => {
              const acciones: Accion[] = []
              if (onEditar) acciones.push({ etiqueta: 'Editar', onSeleccionar: () => onEditar(repuesto) })
              if (onEliminar) acciones.push({ etiqueta: 'Eliminar', peligro: true, onSeleccionar: () => onEliminar(repuesto) })
              return (
                <tr key={repuesto.id}>
                  <td>{repuesto.nombre}</td>
                  <td className="numero">$ {importe(repuesto.precio)}</td>
                  {(onEditar || onEliminar) && <td className="acciones-celda">
                    <MenuAcciones etiqueta={`Acciones para ${repuesto.nombre}`} acciones={acciones} />
                  </td>}
                </tr>
              )
            })}
          </tbody>
        </Tabla>
        <Paginacion meta={catalogo.data.meta} cargando={catalogo.isFetching} onCambiar={setPagina} />
      </>}
      {catalogo.data && onSeleccionar && <>
        <ul className="lista">
          {catalogo.data.repuestos.map((repuesto) => (
            <li key={repuesto.id} className="tarjeta fila-item">
              <div className="item-datos">
                <strong>{repuesto.nombre}</strong>
                <span>Precio de referencia: $ {importe(repuesto.precio)}</span>
              </div>
              {onSeleccionar && <button type="button" className="secundario"
                onClick={() => onSeleccionar(repuesto)} aria-label={`Usar ${repuesto.nombre}`}>
                Usar
              </button>}
              {onEditar && <button type="button" className="secundario accion-catalogo"
                onClick={() => onEditar(repuesto)} aria-label={`Editar ${repuesto.nombre}`}>
                Editar
              </button>}
              {onEliminar && <button type="button" className="accion-catalogo eliminar"
                onClick={() => onEliminar(repuesto)} aria-label={`Eliminar ${repuesto.nombre}`}>
                Eliminar
              </button>}
            </li>
          ))}
        </ul>
        <Paginacion meta={catalogo.data.meta} cargando={catalogo.isFetching} onCambiar={setPagina} />
      </>}
    </section>
  )
}
