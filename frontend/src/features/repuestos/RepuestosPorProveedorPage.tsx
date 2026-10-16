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

      {compras.isPending && <p className="estado">Cargando compras…</p>}
      {compras.isError && !errores.desde && !errores.hasta && (
        <p className="error" role="alert">
          {errorMessage(compras.error, 'No se pudieron cargar las compras.')}
        </p>
      )}

      {compras.data && compras.data.repuestos.length === 0 && (
        <p className="estado">
          {hayFiltros ? 'No hay compras valorizadas con esos filtros.' : 'Todavía no hay compras valorizadas.'}
        </p>
      )}

      {compras.data && compras.data.proveedores.length > 0 && (
        <>
          <ul className="lista" aria-label="Totales por proveedor" aria-busy={compras.isPlaceholderData}>
            {compras.data.proveedores.map((item) => (
              <li key={item.proveedor ?? 'sin-proveedor'} className="tarjeta fila-item">
                <div className="item-datos">
                  <strong>{nombreProveedor(item.proveedor)}</strong>
                  <span>
                    {item.cantidad_compras} {item.cantidad_compras === 1 ? 'compra' : 'compras'}
                  </span>
                </div>
                <strong>$ {importe(item.total_comprado)}</strong>
              </li>
            ))}
          </ul>
          <p className="resumen-saldo" role="status">
            <span>Total comprado</span>
            <strong>$ {importe(compras.data.total_comprado)}</strong>
          </p>
        </>
      )}

      {compras.data && compras.data.repuestos.length > 0 && (
        <>
          <h2>Compras</h2>
          <ul className="lista" aria-busy={compras.isPlaceholderData}>
            {compras.data.repuestos.map((repuesto) => (
              <li key={repuesto.id} className="tarjeta item-datos">
                <strong>{repuesto.descripcion}</strong>
                <span>Proveedor: {nombreProveedor(repuesto.proveedor)}</span>
                <span>
                  {repuesto.cantidad} × $ {importe(repuesto.costo_unitario)} · Total: $ {importe(repuesto.total_costo)}
                </span>
                <span>
                  {repuesto.orden.cliente} · {describirVehiculo(repuesto.orden.vehiculo)} · {fechaHora(repuesto.created_at)}
                </span>
                <Link to={`/ordenes/${repuesto.orden.id}`}>Ver orden</Link>
              </li>
            ))}
          </ul>
          <Paginacion meta={compras.data.meta} cargando={compras.isPlaceholderData} onCambiar={irAPagina} />
        </>
      )}
    </section>
  )
}
