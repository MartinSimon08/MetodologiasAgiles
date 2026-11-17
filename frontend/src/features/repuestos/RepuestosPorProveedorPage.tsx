import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { Link, useSearchParams } from 'react-router-dom'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { ErroresCampo } from '../../components/ErroresCampo'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage, fieldErrors } from '../../lib/api'
import { fechaHora, importe } from '../../lib/formato'
import { useDebounce } from '../../lib/useDebounce'
import { describirVehiculo } from '../ordenes/types'
import { listarRepuestosPorProveedor, nombreProveedor } from './api'
import { RepuestosNav } from './RepuestosNav'
import { Cargando } from '../../components/Cargando'
import { EstadoVacio } from '../../components/EstadoVacio'
import { Tabla } from '../../components/Tabla'

export function RepuestosPorProveedorPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)
  const proveedor = searchParams.get('proveedor') ?? ''
  const desde = searchParams.get('desde') ?? ''
  const hasta = searchParams.get('hasta') ?? ''
  const proveedorDebounced = useDebounce(proveedor.trim())

  const compras = useQuery({
    queryKey: ['repuestos-por-proveedor', pagina, proveedorDebounced, desde, hasta],
    queryFn: () => listarRepuestosPorProveedor({
      pagina,
      proveedor: proveedorDebounced || undefined,
      desde: desde || undefined,
      hasta: hasta || undefined,
    }),
    placeholderData: keepPreviousData,
  })

  const errores = fieldErrors(compras.error)

  function actualizar(valores: { pagina?: number; proveedor?: string; desde?: string; hasta?: string }) {
    const siguienteProveedor = valores.proveedor ?? proveedor
    const siguienteDesde = valores.desde ?? desde
    const siguienteHasta = valores.hasta ?? hasta
    const siguientePagina = valores.pagina ?? 1
    const params: Record<string, string> = {}
    if (siguienteProveedor) params.proveedor = siguienteProveedor
    if (siguienteDesde) params.desde = siguienteDesde
    if (siguienteHasta) params.hasta = siguienteHasta
    if (siguientePagina > 1) params.pagina = String(siguientePagina)
    setSearchParams(params, { replace: true })
  }

  function irAPagina(nueva: number) {
    actualizar({ pagina: nueva })
    window.scrollTo({ top: 0 })
  }

  const hayFiltros = Boolean(proveedorDebounced || desde || hasta)

  return (
    <section className="repuestos">
      <RepuestosNav />
      <EncabezadoPagina
        titulo="Compras por proveedor"
        bajada="Filtrá las compras valorizadas para ver cuánto se le compró a cada proveedor."
      />

      <form className="filtros-compras" onSubmit={(event) => event.preventDefault()}>
        <label>
          <span>Proveedor</span>
          <input
            type="search"
            autoComplete="off"
            placeholder="Nombre del proveedor"
            value={proveedor}
            onChange={(event) => actualizar({ proveedor: event.target.value })}
          />
        </label>
        <label>
          <span>Desde</span>
          <input
            type="date"
            value={desde}
            onChange={(event) => actualizar({ desde: event.target.value })}
            aria-invalid={Boolean(errores.desde)}
          />
          <ErroresCampo errores={errores.desde} />
        </label>
        <label>
          <span>Hasta</span>
          <input
            type="date"
            value={hasta}
            onChange={(event) => actualizar({ hasta: event.target.value })}
            aria-invalid={Boolean(errores.hasta)}
          />
          <ErroresCampo errores={errores.hasta} />
        </label>
      </form>

      {compras.isPending && <Cargando />}
      {compras.isError && !errores.desde && !errores.hasta && (
        <p className="error" role="alert">
          {errorMessage(compras.error, 'No se pudieron cargar las compras.')}
        </p>
      )}

      {compras.data && compras.data.repuestos.length === 0 &&
        (hayFiltros ? (
          <EstadoVacio busqueda titulo="Sin resultados" descripcion="No hay compras valorizadas con esos filtros." />
        ) : (
          <EstadoVacio
            titulo="Todavía no hay compras valorizadas"
            descripcion="Acá vas a ver lo comprado a cada proveedor cuando se valoricen repuestos en las órdenes."
          />
        ))}

      {compras.data && compras.data.proveedores.length > 0 && (
        <Tabla etiqueta="Totales por proveedor" ocupada={compras.isPlaceholderData}>
          <thead>
            <tr>
              <th scope="col">Proveedor</th>
              <th scope="col" className="numero">
                Compras
              </th>
              <th scope="col" className="numero">
                Total comprado
              </th>
            </tr>
          </thead>
          <tbody>
            {compras.data.proveedores.map((item) => (
              <tr key={item.proveedor ?? 'sin-proveedor'}>
                <td>{nombreProveedor(item.proveedor)}</td>
                <td className="numero">{item.cantidad_compras}</td>
                <td className="numero">$ {importe(item.total_comprado)}</td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr>
              <th scope="row" colSpan={2}>
                Total comprado
              </th>
              <td className="numero">$ {importe(compras.data.total_comprado)}</td>
            </tr>
          </tfoot>
        </Tabla>
      )}

      {compras.data && compras.data.repuestos.length > 0 && (
        <>
          <h2>Compras</h2>
          <Tabla etiqueta="Compras" ocupada={compras.isPlaceholderData}>
            <thead>
              <tr>
                <th scope="col">Repuesto</th>
                <th scope="col">Proveedor</th>
                <th scope="col" className="numero">
                  Cantidad
                </th>
                <th scope="col" className="numero">
                  Costo unitario
                </th>
                <th scope="col" className="numero">
                  Total
                </th>
                <th scope="col">Orden</th>
                <th scope="col">Fecha</th>
              </tr>
            </thead>
            <tbody>
              {compras.data.repuestos.map((repuesto) => (
                <tr key={repuesto.id}>
                  <td>
                    {repuesto.descripcion}
                    {repuesto.con_ajustes && <span className="secundaria">Con devoluciones o cambios</span>}
                  </td>
                  <td>{nombreProveedor(repuesto.proveedor)}</td>
                  <td className="numero">{repuesto.cantidad}</td>
                  <td className="numero">$ {importe(repuesto.costo_unitario)}</td>
                  <td className="numero">$ {importe(repuesto.total_costo)}</td>
                  <td>
                    <Link to={`/ordenes/${repuesto.orden.id}`} className="enlace-fila">
                      {repuesto.orden.cliente}
                    </Link>
                    <span className="secundaria">{describirVehiculo(repuesto.orden.vehiculo)}</span>
                  </td>
                  <td className="fecha">{fechaHora(repuesto.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </Tabla>
          <Paginacion meta={compras.data.meta} cargando={compras.isPlaceholderData} onCambiar={irAPagina} />
        </>
      )}
    </section>
  )
}
