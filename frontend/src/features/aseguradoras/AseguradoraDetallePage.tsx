import { useQuery } from '@tanstack/react-query'
import { Link, useParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { EnlaceEntidad } from '../../components/EnlaceEntidad'
import { etiquetaVehiculo } from '../../lib/vehiculo'
import { FilaEnlace } from '../../components/FilaEnlace'
import { Tabla } from '../../components/Tabla'
import { errorMessage } from '../../lib/api'
import { fecha } from '../../lib/formato'
import { obtenerAseguradora } from './api'

export function AseguradoraDetallePage() {
  const aseguradoraId = Number(useParams().id)
  const aseguradora = useQuery({
    queryKey: ['aseguradora', aseguradoraId],
    queryFn: () => obtenerAseguradora(aseguradoraId),
  })
  const datos = aseguradora.data

  return (
    <section className="detalle-entidad">
      <Link to="/aseguradoras" className="volver">
        ← Volver a aseguradoras
      </Link>

      {aseguradora.isPending && <Cargando />}
      {aseguradora.isError && (
        <p className="error" role="alert">
          {errorMessage(aseguradora.error, 'No se pudo cargar la aseguradora.')}
        </p>
      )}

      {datos && (
        <>
          <header className="encabezado">
            <div>
              <h1>{datos.nombre}</h1>
              <p className="estado">{[datos.telefono, datos.email].filter(Boolean).join(' · ') || 'Sin contacto cargado'}</p>
            </div>
            {!datos.activa && <span className="insignia insignia-desactivado">Desactivada</span>}
          </header>

          <section className="tarjeta">
            <h2>Casos</h2>
            {datos.casos.length === 0 ? (
              <p className="estado">Todavía no tiene casos.</p>
            ) : (
              <Tabla etiqueta="Casos de la aseguradora">
                <tbody>
                  {datos.casos.map((caso) => (
                    <FilaEnlace key={caso.id} a={`/casos/${caso.id}`}>
                      <td>
                        <EnlaceEntidad a={`/casos/${caso.id}`}>{caso.numero_siniestro}</EnlaceEntidad>
                      </td>
                      <td>
                        <EnlaceEntidad a={`/clientes/${caso.asegurado.id}`}>{caso.asegurado.nombre}</EnlaceEntidad>
                      </td>
                      <td>{etiquetaVehiculo(caso.vehiculo)}</td>
                      <td className="fecha">
                        {caso.fecha_turno ? fecha(caso.fecha_turno) : <span className="sin-dato">Sin turno</span>}
                      </td>
                    </FilaEnlace>
                  ))}
                </tbody>
              </Tabla>
            )}
          </section>
        </>
      )}
    </section>
  )
}
