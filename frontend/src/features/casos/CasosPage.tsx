import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { BotonNuevo } from '../../components/BotonNuevo'
import { Buscador } from '../../components/Buscador'
import { Cargando } from '../../components/Cargando'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { fechaHora } from '../../lib/formato'
import { useDebounce } from '../../lib/useDebounce'
import { fechaCorta, ingresarCaso, listarCasos, type Caso } from './api'
import { CasosNav } from './CasosNav'
import { NuevoCasoForm } from './NuevoCasoForm'
import { TurnoForm } from './TurnoForm'

export function CasosPage() {
  const [abriendo, setAbriendo] = useState(false)
  const [turnoId, setTurnoId] = useState<number | null>(null)
  const [aviso, setAviso] = useState<string | null>(null)
  const [busqueda, setBusqueda] = useState('')
  const [pagina, setPagina] = useState(1)
  const buscar = useDebounce(busqueda.trim())
  const queryClient = useQueryClient()

  const casos = useQuery({
    queryKey: ['casos', buscar, pagina],
    queryFn: () => listarCasos(buscar, pagina),
    placeholderData: keepPreviousData,
  })

  const ingresar = useMutation({
    mutationFn: (caso: Caso) => ingresarCaso(caso.id),
    onSuccess: async (caso) => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: ['casos'] }),
        queryClient.invalidateQueries({ queryKey: ['ordenes'] }),
      ])
      setAviso(`Ingresó el vehículo del caso ${caso.numero_siniestro} y se abrió su orden.`)
    },
  })

  return (
    <section className="casos">
      <CasosNav />
      <EncabezadoPagina titulo="Casos" bajada="Siniestros de aseguradoras para planificar antes de que el vehículo ingrese." />

      {aviso && (
        <p className="aviso" role="status">
          {aviso}
        </p>
      )}

      {ingresar.isError && (
        <p className="error" role="alert">
          {errorMessage(ingresar.error, 'No se pudo ingresar el vehículo.')}
        </p>
      )}

      {abriendo && (
        <NuevoCasoForm
          onCancelar={() => setAbriendo(false)}
          onAbierto={(caso) => {
            setAbriendo(false)
            setAviso(`Se abrió el caso ${caso.numero_siniestro} de ${caso.aseguradora.nombre}.`)
          }}
        />
      )}

      <Buscador
        etiqueta="Buscar caso"
        placeholder="Siniestro, patente, asegurado o aseguradora"
        valor={busqueda}
        onCambiar={(valor) => {
          setBusqueda(valor)
          setPagina(1)
        }}
        accion={
          abriendo ? undefined : (
            <BotonNuevo
              onClick={() => {
                setAviso(null)
                setAbriendo(true)
              }}
            >
              Nuevo caso
            </BotonNuevo>
          )
        }
      />

      {casos.isPending && <Cargando />}
      {casos.isError && (
        <p className="error" role="alert">
          {errorMessage(casos.error, 'No se pudieron cargar los casos.')}
        </p>
      )}

      {casos.data?.casos.length === 0 && (
        <p className="estado">{buscar ? 'No hay casos que coincidan.' : 'Todavía no hay casos abiertos.'}</p>
      )}

      {casos.data && casos.data.casos.length > 0 && (
        <>
          <ul className="lista" aria-busy={casos.isPlaceholderData}>
            {casos.data.casos.map((caso) => (
              <li key={caso.id} className="tarjeta item">
                <div className="item-datos">
                  <strong>
                    Siniestro {caso.numero_siniestro} · {caso.aseguradora.nombre}
                  </strong>
                  <span>
                    {caso.asegurado.nombre} · <span className="patente">{caso.vehiculo.patente}</span>
                    {[caso.vehiculo.marca, caso.vehiculo.modelo].filter(Boolean).length > 0 &&
                      ` ${[caso.vehiculo.marca, caso.vehiculo.modelo].filter(Boolean).join(' ')}`}
                  </span>
                  {caso.descripcion && <span>{caso.descripcion}</span>}
                  <span>Abierto el {fechaHora(caso.created_at)}</span>
                  {caso.fecha_turno !== null && <span>Turno: {fechaCorta(caso.fecha_turno)}</span>}
                  {caso.cambios_turno
                    .filter((cambio) => cambio.fecha_anterior !== null)
                    .map((cambio) => (
                      <small key={cambio.id} className="cambio-turno">
                        Reprogramado del {fechaCorta(cambio.fecha_anterior!)} al {fechaCorta(cambio.fecha_nueva)} por{' '}
                        {cambio.registrado_por.nombre} el {fechaHora(cambio.created_at)}
                      </small>
                    ))}
                </div>
                <div className="item-insignias">
                  {caso.fecha_turno === null && <span className="insignia insignia-pendiente">Sin turno</span>}
                  {caso.orden_id === null ? (
                    <>
                      <span className="insignia insignia-desactivado">Sin orden</span>
                      {turnoId !== caso.id && (
                        <button
                          type="button"
                          className="secundario"
                          onClick={() => {
                            setAviso(null)
                            setTurnoId(caso.id)
                          }}
                        >
                          {caso.fecha_turno === null ? 'Asignar turno' : 'Reprogramar'}
                        </button>
                      )}
                      {caso.fecha_turno !== null && (
                        <button
                          type="button"
                          disabled={ingresar.isPending}
                          onClick={() => {
                            setAviso(null)
                            ingresar.mutate(caso)
                          }}
                        >
                          Ingresar vehículo
                        </button>
                      )}
                    </>
                  ) : (
                    <Link to={`/ordenes/${caso.orden_id}`} className="insignia insignia-abierta">
                      Ingresado · orden #{caso.orden_id}
                    </Link>
                  )}
                </div>
                {turnoId === caso.id && (
                  <TurnoForm
                    casoId={caso.id}
                    numeroSiniestro={caso.numero_siniestro}
                    fechaActual={caso.fecha_turno}
                    onCancelar={() => setTurnoId(null)}
                    onListo={(actualizado) => {
                      setTurnoId(null)
                      setAviso(
                        `${caso.fecha_turno === null ? 'Se asignó' : 'Se reprogramó'} el turno del caso ${actualizado.numero_siniestro} para el ${fechaCorta(actualizado.fecha_turno!)}.`,
                      )
                    }}
                  />
                )}
              </li>
            ))}
          </ul>
          <Paginacion meta={casos.data.meta} cargando={casos.isPlaceholderData} onCambiar={setPagina} />
        </>
      )}
    </section>
  )
}
