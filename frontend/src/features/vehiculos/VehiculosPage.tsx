import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { BotonNuevo } from '../../components/BotonNuevo'
import { Buscador } from '../../components/Buscador'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { useDebounce } from '../../lib/useDebounce'
import { listarVehiculos, type Vehiculo } from './api'
import { CambiarDuenioForm } from './CambiarDuenioForm'
import { NuevoVehiculoForm } from './NuevoVehiculoForm'
import { Cargando } from '../../components/Cargando'
import { Dialogo } from '../../components/Dialogo'
import { EstadoVacio } from '../../components/EstadoVacio'
import { MenuAcciones } from '../../components/MenuAcciones'
import { Tabla } from '../../components/Tabla'
import { usePorPagina } from '../../lib/paginacion'

function descripcion(vehiculo: Vehiculo) {
  return [vehiculo.marca, vehiculo.modelo, vehiculo.anio].filter(Boolean).join(' ')
}

export function VehiculosPage() {
  const [registrando, setRegistrando] = useState(false)
  const [cambiando, setCambiando] = useState<Vehiculo | null>(null)
  const [aviso, setAviso] = useState<string | null>(null)

  const navigate = useNavigate()
  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)
  const [porPagina, setPorPagina] = usePorPagina()
  const busqueda = searchParams.get('q') ?? ''
  const q = useDebounce(busqueda.trim())

  const vehiculos = useQuery({
    queryKey: ['vehiculos', pagina, q, porPagina],
    queryFn: () => listarVehiculos(pagina, q, porPagina),
    placeholderData: keepPreviousData,
  })

  function actualizarFiltros(nuevaPagina: number, nuevaBusqueda: string) {
    const params: Record<string, string> = {}
    if (nuevaBusqueda) params.q = nuevaBusqueda
    if (nuevaPagina > 1) params.pagina = String(nuevaPagina)
    setCambiando(null)
    setSearchParams(params, { replace: true })
  }

  function irAPagina(nueva: number) {
    actualizarFiltros(nueva, busqueda)
    window.scrollTo({ top: 0 })
  }

  const nuevo = !registrando && (
    <BotonNuevo
      onClick={() => {
        setAviso(null)
        setRegistrando(true)
      }}
    >
      Nuevo vehículo
    </BotonNuevo>
  )

  return (
    <section className="vehiculos">
      <EncabezadoPagina titulo="Vehículos" bajada="Vehículos registrados y su dueño actual.">
        {nuevo}
      </EncabezadoPagina>

      {aviso && (
        <p className="aviso" role="status">
          {aviso}
        </p>
      )}

      {registrando && (
        <NuevoVehiculoForm
          onRegistrado={(vehiculo) => {
            setRegistrando(false)
            setAviso(`Se registró ${vehiculo.patente} a nombre de ${vehiculo.cliente.nombre}.`)
          }}
          onVerExistente={(patente) => {
            setRegistrando(false)
            actualizarFiltros(1, patente)
          }}
          onCancelar={() => setRegistrando(false)}
        />
      )}

      <Buscador
        etiqueta="Buscar vehículo"
        placeholder="Patente, nombre o teléfono del dueño"
        valor={busqueda}
        onCambiar={(valor) => actualizarFiltros(1, valor)}
      />

      {vehiculos.isPending && <Cargando />}
      {vehiculos.isError && (
        <p className="error" role="alert">
          {errorMessage(vehiculos.error, 'No se pudieron cargar los vehículos.')}
        </p>
      )}

      {vehiculos.data?.vehiculos.length === 0 &&
        (q ? (
          <EstadoVacio
            busqueda
            titulo="Sin resultados"
            descripcion={`No hay vehículos que coincidan con “${q}”.`}
          />
        ) : (
          <EstadoVacio
            titulo="Todavía no hay vehículos"
            descripcion="Registrá un vehículo y asignale su dueño para poder abrirle órdenes."
          />
        ))}

      {vehiculos.data && vehiculos.data.vehiculos.length > 0 && (
        <Tabla etiqueta="Vehículos" ocupada={vehiculos.isPlaceholderData}>
          <thead>
            <tr>
              <th scope="col">Patente</th>
              <th scope="col">Vehículo</th>
              <th scope="col" className="numero">
                Kilometraje
              </th>
              <th scope="col">Dueño</th>
              <th scope="col" className="acciones-celda">
                <span className="solo-lectores">Acciones</span>
              </th>
            </tr>
          </thead>
          <tbody>
            {vehiculos.data.vehiculos.map((vehiculo) => (
              <tr key={vehiculo.id}>
                <td>
                  <strong className="patente">{vehiculo.patente}</strong>
                </td>
                <td>{descripcion(vehiculo) || <span className="sin-dato">—</span>}</td>
                <td className="numero">
                  {vehiculo.kilometraje !== null ? (
                    `${vehiculo.kilometraje.toLocaleString('es-AR')} km`
                  ) : (
                    <span className="sin-dato">—</span>
                  )}
                </td>
                <td>
                  {vehiculo.cliente.nombre}
                  <a className="secundaria" href={`tel:${vehiculo.cliente.telefono}`}>
                    {vehiculo.cliente.telefono}
                  </a>
                </td>
                <td className="acciones-celda">
                  <MenuAcciones
                    etiqueta={`Acciones para ${vehiculo.patente}`}
                    acciones={[
                      {
                        etiqueta: 'Ver historial',
                        onSeleccionar: () => navigate(`/vehiculos/${vehiculo.id}/historial`),
                      },
                      {
                        etiqueta: 'Cambiar dueño',
                        onSeleccionar: () => {
                          setAviso(null)
                          setCambiando(vehiculo)
                        },
                      },
                    ]}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </Tabla>
      )}

      {cambiando && (
        <Dialogo onCerrar={() => setCambiando(null)}>
          <div className="tarjeta">
            <h2>Cambiar dueño de {cambiando.patente}</h2>
            <CambiarDuenioForm
              vehiculo={cambiando}
              onListo={(actualizado) => {
                setCambiando(null)
                setAviso(`${actualizado.patente} ahora es de ${actualizado.cliente.nombre}.`)
              }}
              onCancelar={() => setCambiando(null)}
            />
          </div>
        </Dialogo>
      )}

      {vehiculos.data && (
        <Paginacion
          meta={vehiculos.data.meta}
          cargando={vehiculos.isPlaceholderData}
          onCambiar={irAPagina}
          porPagina={porPagina}
          onCambiarPorPagina={(valor) => {
            setPorPagina(valor)
            irAPagina(1)
          }}
        />
      )}
    </section>
  )
}
