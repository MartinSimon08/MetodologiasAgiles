import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { EnlaceEntidad } from '../../components/EnlaceEntidad'
import { etiquetaVehiculo } from '../../lib/vehiculo'
import { errorMessage } from '../../lib/api'
import { fecha, fechaHora } from '../../lib/formato'
import { avisarAsegurado, obtenerCaso } from './api'

export function CasoDetallePage() {
  const casoId = Number(useParams().id)
  const caso = useQuery({ queryKey: ['caso', casoId], queryFn: () => obtenerCaso(casoId) })
  const datos = caso.data
  const queryClient = useQueryClient()
  const [mensaje, setMensaje] = useState<string | null>(null)
  const [enviado, setEnviado] = useState(false)

  const avisar = useMutation({
    mutationFn: (texto: string) => avisarAsegurado(casoId, texto),
    onSuccess: async () => {
      setEnviado(true)
      setMensaje(null)
      await queryClient.invalidateQueries({ queryKey: ['caso', casoId] })
    },
  })

  const sugerido = datos
    ? `Hola ${datos.asegurado.nombre}, tu vehículo ${datos.vehiculo.patente} ya está listo para retirar. ` +
      `Caso ${datos.numero_siniestro} - ${datos.aseguradora.nombre}.`
    : ''
  const texto = mensaje ?? sugerido

  return (
    <section className="detalle-entidad">
      <Link to="/casos" className="volver">
        ← Volver a casos
      </Link>

      {caso.isPending && <Cargando />}
      {caso.isError && (
        <p className="error" role="alert">
          {errorMessage(caso.error, 'No se pudo cargar el caso.')}
        </p>
      )}

      {datos && (
        <>
          <header className="encabezado">
            <div>
              <h1>Siniestro {datos.numero_siniestro}</h1>
              <p className="estado">
                <EnlaceEntidad a={`/aseguradoras/${datos.aseguradora.id}`}>{datos.aseguradora.nombre}</EnlaceEntidad>
              </p>
            </div>
            {datos.orden ? (
              <Link to={`/ordenes/${datos.orden.id}`} className="insignia insignia-abierta">
                Ingresado · orden #{datos.orden.id}
              </Link>
            ) : (
              <span className="insignia insignia-desactivado">Sin orden</span>
            )}
          </header>

          <section className="tarjeta datos-entidad">
            <p>
              <strong>Asegurado:</strong>{' '}
              <EnlaceEntidad a={`/clientes/${datos.asegurado.id}`}>{datos.asegurado.nombre}</EnlaceEntidad>
            </p>
            <p>
              <strong>Vehículo:</strong>{' '}
              <EnlaceEntidad a={`/vehiculos/${datos.vehiculo.id}/historial`}>{etiquetaVehiculo(datos.vehiculo)}</EnlaceEntidad>
            </p>
            <p>
              <strong>Turno:</strong> {datos.fecha_turno ? fecha(datos.fecha_turno) : 'Sin turno'}
            </p>
            {datos.descripcion && (
              <p>
                <strong>Descripción:</strong> {datos.descripcion}
              </p>
            )}
          </section>

          <section className="tarjeta">
            <h2>Avisar al asegurado</h2>
            <p className="estado">Se registra el aviso para {datos.asegurado.nombre}. Podés editar el mensaje antes de enviarlo.</p>
            <form
              className="formulario"
              onSubmit={(evento) => {
                evento.preventDefault()
                setEnviado(false)
                avisar.mutate(texto)
              }}
            >
              <label>
                Mensaje
                <textarea
                  rows={3}
                  value={texto}
                  maxLength={1000}
                  onChange={(evento) => {
                    setEnviado(false)
                    setMensaje(evento.target.value)
                  }}
                />
              </label>
              {avisar.isError && (
                <p className="error" role="alert">
                  {errorMessage(avisar.error, 'No se pudo enviar el aviso.')}
                </p>
              )}
              {enviado && (
                <p className="aviso" role="status">
                  Aviso enviado.
                </p>
              )}
              <button type="submit" disabled={avisar.isPending || !texto.trim()}>
                Avisar al asegurado
              </button>
            </form>
          </section>

          {datos.cambios_turno.length > 0 && (
            <section className="tarjeta">
              <h2>Historial de turnos</h2>
              <ul className="lineas-cierre">
                {datos.cambios_turno.map((cambio) => (
                  <li key={cambio.id}>
                    <span>
                      {cambio.fecha_anterior ? `${fecha(cambio.fecha_anterior)} → ` : ''}
                      {fecha(cambio.fecha_nueva)}
                      <small>Por {cambio.registrado_por.nombre}</small>
                    </span>
                    <span>{fechaHora(cambio.created_at)}</span>
                  </li>
                ))}
              </ul>
            </section>
          )}

          {datos.notificaciones.length > 0 && (
            <section className="tarjeta">
              <h2>Avisos al asegurado</h2>
              <ul className="lineas-cierre">
                {datos.notificaciones.map((aviso) => (
                  <li key={aviso.id}>
                    <span>
                      {aviso.contenido}
                      <small>{aviso.medio}</small>
                    </span>
                    <span>{fechaHora(aviso.enviada_en)}</span>
                  </li>
                ))}
              </ul>
            </section>
          )}
        </>
      )}
    </section>
  )
}
