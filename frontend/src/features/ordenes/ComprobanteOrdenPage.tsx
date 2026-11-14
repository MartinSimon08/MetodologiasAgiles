import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { errorMessage } from '../../lib/api'
import { fechaHora, importe } from '../../lib/formato'
import { obtenerComprobante } from './api'
import { describirVehiculo, type ComprobanteOrden } from './types'

function resumenTexto(comprobante: ComprobanteOrden) {
  return [
    `Comprobante de trabajo · Orden #${comprobante.orden_id}`,
    `Cliente: ${comprobante.cliente.nombre}`,
    `Vehículo: ${describirVehiculo(comprobante.vehiculo)}`,
    `Mano de obra: $ ${importe(comprobante.mano_de_obra)}`,
    `Repuestos: $ ${importe(comprobante.total_repuestos)}`,
    `Total: $ ${importe(comprobante.total)}`,
  ].join('\n')
}

export function ComprobanteOrdenPage() {
  const { id } = useParams()
  const ordenId = Number(id)
  const [aviso, setAviso] = useState<string | null>(null)

  const comprobante = useQuery({
    queryKey: ['comprobante', ordenId],
    queryFn: () => obtenerComprobante(ordenId),
  })

  async function compartir() {
    const datos = comprobante.data
    if (!datos) return

    const texto = resumenTexto(datos)
    if (typeof navigator.share === 'function') {
      try {
        await navigator.share({
          title: `Comprobante orden #${datos.orden_id}`,
          text: texto,
          url: window.location.href,
        })
        return
      } catch {
        return
      }
    }

    try {
      await navigator.clipboard.writeText(texto)
      setAviso('El comprobante se copió al portapapeles.')
    } catch {
      setAviso('No se pudo compartir el comprobante.')
    }
  }

  return (
    <section className="orden-detalle comprobante-orden">
      <Link to={`/ordenes/${ordenId}`} className="volver">
        ← Volver a la orden
      </Link>

      {comprobante.isPending && <Cargando />}
      {comprobante.isError && (
        <p className="error" role="alert">
          {errorMessage(comprobante.error, 'No se pudo cargar el comprobante.')}
        </p>
      )}

      {comprobante.data && (
        <>
          <article className="tarjeta comprobante-documento">
            <header className="comprobante-cabecera">
              <div>
                <h1>Comprobante de trabajo</h1>
                <p>Orden #{comprobante.data.orden_id}</p>
              </div>
              <div className="comprobante-cierre">
                <span>Cerrada</span>
                {comprobante.data.cerrada_en && <strong>{fechaHora(comprobante.data.cerrada_en)}</strong>}
                {comprobante.data.cerrada_por && <small>por {comprobante.data.cerrada_por.nombre}</small>}
              </div>
            </header>

            <dl className="comprobante-datos">
              <div>
                <dt>Cliente</dt>
                <dd>{comprobante.data.cliente.nombre}</dd>
              </div>
              <div>
                <dt>Teléfono</dt>
                <dd>{comprobante.data.cliente.telefono}</dd>
              </div>
              <div>
                <dt>Vehículo</dt>
                <dd>{describirVehiculo(comprobante.data.vehiculo)}</dd>
              </div>
            </dl>

            <section className="bloque-cierre">
              <h3>Mano de obra</h3>
              {comprobante.data.tareas.length === 0 && <p className="estado">Sin tareas facturadas.</p>}
              <ul className="lineas-cierre">
                {comprobante.data.tareas.map((tarea) => (
                  <li key={tarea.id}>
                    <span>
                      {tarea.descripcion}
                      <small>{tarea.mecanico ? `Hecha por ${tarea.mecanico.nombre}` : 'Sin responsable'}</small>
                    </span>
                    <span>{tarea.precio != null ? `$ ${importe(tarea.precio)}` : 'Sin precio'}</span>
                  </li>
                ))}
              </ul>
            </section>

            <section className="bloque-cierre">
              <h3>Repuestos</h3>
              {comprobante.data.repuestos.length === 0 && <p className="estado">Sin repuestos facturados.</p>}
              <ul className="lineas-cierre">
                {comprobante.data.repuestos.map((repuesto) => (
                  <li key={repuesto.id}>
                    <span>
                      {repuesto.descripcion}
                      <small>Cantidad: {repuesto.cantidad}</small>
                    </span>
                    <span>$ {importe(repuesto.precio_cliente ?? 0)}</span>
                  </li>
                ))}
              </ul>
            </section>

            <dl className="totales-cierre">
              <div>
                <dt>Mano de obra</dt>
                <dd>$ {importe(comprobante.data.mano_de_obra)}</dd>
              </div>
              <div>
                <dt>Repuestos</dt>
                <dd>$ {importe(comprobante.data.total_repuestos)}</dd>
              </div>
              <div className="total">
                <dt>Total</dt>
                <dd>$ {importe(comprobante.data.total)}</dd>
              </div>
              {Number(comprobante.data.adelantado) > 0 && (
                <>
                  <div>
                    <dt>Adelantado</dt>
                    <dd>$ {importe(comprobante.data.adelantado)}</dd>
                  </div>
                  <div>
                    <dt>Saldo a cobrar</dt>
                    <dd>$ {importe(comprobante.data.saldo)}</dd>
                  </div>
                </>
              )}
            </dl>
          </article>

          {aviso && (
            <p className="estado" role="status">
              {aviso}
            </p>
          )}

          <div className="acciones comprobante-acciones">
            <button type="button" className="secundario" onClick={() => window.print()}>
              Imprimir
            </button>
            <button type="button" onClick={compartir}>
              Compartir
            </button>
          </div>
        </>
      )}
    </section>
  )
}
