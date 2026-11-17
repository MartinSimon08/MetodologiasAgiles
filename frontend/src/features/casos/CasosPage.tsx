import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { BotonNuevo } from '../../components/BotonNuevo'
import { Buscador } from '../../components/Buscador'
import { Cargando } from '../../components/Cargando'
import { Dialogo } from '../../components/Dialogo'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { EstadoVacio } from '../../components/EstadoVacio'
import { MenuAcciones, type Accion } from '../../components/MenuAcciones'
import { Paginacion } from '../../components/Paginacion'
import { Tabla } from '../../components/Tabla'
import { errorMessage } from '../../lib/api'
import { fechaHora } from '../../lib/formato'
import { useDebounce } from '../../lib/useDebounce'
import { fechaCorta, ingresarCaso, listarCasos, type Caso } from './api'
import { CasosNav } from './CasosNav'
import { NuevoCasoForm } from './NuevoCasoForm'
import { TurnoForm } from './TurnoForm'

export function CasosPage() {
  const [abriendo, setAbriendo] = useState(false)
  const [turnoDe, setTurnoDe] = useState<Caso | null>(null)
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
      <EncabezadoPagina titulo="Casos" bajada="Siniestros de aseguradoras para planificar antes de que el vehículo ingrese.">
        {!abriendo && (
          <BotonNuevo
            onClick={() => {
              setAviso(null)
              setAbriendo(true)
            }}
          >
            Nuevo caso
          </BotonNuevo>
        )}
      </EncabezadoPagina>
      <CasosNav />

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
      />

      {casos.isPending && <Cargando />}
      {casos.isError && (
        <p className="error" role="alert">
          {errorMessage(casos.error, 'No se pudieron cargar los casos.')}
        </p>
      )}

      {casos.data?.casos.length === 0 &&
        (buscar ? (
          <EstadoVacio busqueda titulo="Sin resultados" descripcion="No hay casos que coincidan." />
        ) : (
          <EstadoVacio
            titulo="Todavía no hay casos abiertos"
            descripcion="Abrí un caso cuando una aseguradora derive un siniestro al taller."
          />
        ))}

      {casos.data && casos.data.casos.length > 0 && (
        <>
          <Tabla etiqueta="Casos" ocupada={casos.isPlaceholderData}>
            <thead>
              <tr>
                <th scope="col">Siniestro</th>
                <th scope="col">Asegurado</th>
                <th scope="col">Abierto</th>
                <th scope="col">Turno</th>
                <th scope="col">Orden</th>
                <th scope="col" className="acciones-celda">
                  <span className="solo-lectores">Acciones</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {casos.data.casos.map((caso) => {
                const vehiculo = [caso.vehiculo.marca, caso.vehiculo.modelo].filter(Boolean).join(' ')
                const acciones: Accion[] = []
                if (caso.orden_id === null) {
                  acciones.push({
                    etiqueta: caso.fecha_turno === null ? 'Asignar turno' : 'Reprogramar turno',
                    onSeleccionar: () => {
                      setAviso(null)
                      setTurnoDe(caso)
                    },
                  })
                  if (caso.fecha_turno !== null) {
                    acciones.push({
                      etiqueta: 'Ingresar vehículo',
                      deshabilitada: ingresar.isPending,
                      onSeleccionar: () => {
                        setAviso(null)
                        ingresar.mutate(caso)
                      },
                    })
                  }
                }

                return (
                  <tr key={caso.id}>
                    <td>
                      <strong>{caso.numero_siniestro}</strong>
                      <span className="secundaria">{caso.aseguradora.nombre}</span>
                      {caso.descripcion && <span className="secundaria">{caso.descripcion}</span>}
                    </td>
                    <td>
                      {caso.asegurado.nombre}
                      <span className="secundaria">
                        <span className="patente">{caso.vehiculo.patente}</span>
                        {vehiculo && ` ${vehiculo}`}
                      </span>
                    </td>
                    <td className="fecha">{fechaHora(caso.created_at)}</td>
                    <td>
                      {caso.fecha_turno === null ? (
                        <span className="insignia insignia-pendiente">Sin turno</span>
                      ) : (
                        <span className="fecha">{fechaCorta(caso.fecha_turno)}</span>
                      )}
                      {caso.cambios_turno
                        .filter((cambio) => cambio.fecha_anterior !== null)
                        .map((cambio) => (
                          <small key={cambio.id} className="secundaria cambio-turno">
                            Reprogramado del {fechaCorta(cambio.fecha_anterior!)} al {fechaCorta(cambio.fecha_nueva)} por{' '}
                            {cambio.registrado_por.nombre} el {fechaHora(cambio.created_at)}
                          </small>
                        ))}
                    </td>
                    <td>
                      {caso.orden_id === null ? (
                        <span className="insignia insignia-desactivado">Sin orden</span>
                      ) : (
                        <Link to={`/ordenes/${caso.orden_id}`} className="insignia insignia-abierta">
                          Orden #{caso.orden_id}
                        </Link>
                      )}
                    </td>
                    <td className="acciones-celda">
                      <MenuAcciones etiqueta={`Acciones para el caso ${caso.numero_siniestro}`} acciones={acciones} />
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </Tabla>
          <Paginacion meta={casos.data.meta} cargando={casos.isPlaceholderData} onCambiar={setPagina} />
        </>
      )}

      {turnoDe && (
        <Dialogo onCerrar={() => setTurnoDe(null)}>
          <div className="tarjeta">
            <h2>
              {turnoDe.fecha_turno === null ? 'Asignar turno' : 'Reprogramar turno'} · caso {turnoDe.numero_siniestro}
            </h2>
            <TurnoForm
              casoId={turnoDe.id}
              numeroSiniestro={turnoDe.numero_siniestro}
              fechaActual={turnoDe.fecha_turno}
              onCancelar={() => setTurnoDe(null)}
              onListo={(actualizado) => {
                setTurnoDe(null)
                setAviso(
                  `${turnoDe.fecha_turno === null ? 'Se asignó' : 'Se reprogramó'} el turno del caso ${actualizado.numero_siniestro} para el ${fechaCorta(actualizado.fecha_turno!)}.`,
                )
              }}
            />
          </div>
        </Dialogo>
      )}
    </section>
  )
}
