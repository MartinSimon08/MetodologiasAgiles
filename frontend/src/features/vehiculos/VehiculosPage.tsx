import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Buscador } from '../../components/Buscador'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { useDebounce } from '../../lib/useDebounce'
import { listarVehiculos, type Vehiculo } from './api'
import { CambiarDuenioForm } from './CambiarDuenioForm'
import { NuevoVehiculoForm } from './NuevoVehiculoForm'

function descripcion(vehiculo: Vehiculo) {
  return [vehiculo.marca, vehiculo.modelo, vehiculo.anio].filter(Boolean).join(' ')
}

export function VehiculosPage() {
  const [registrando, setRegistrando] = useState(false)
  const [cambiandoId, setCambiandoId] = useState<number | null>(null)
  const [aviso, setAviso] = useState<string | null>(null)

  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)
  const busqueda = searchParams.get('q') ?? ''
  const q = useDebounce(busqueda.trim())

  const vehiculos = useQuery({
    queryKey: ['vehiculos', pagina, q],
    queryFn: () => listarVehiculos(pagina, q),
    placeholderData: keepPreviousData,
  })

  function actualizarFiltros(nuevaPagina: number, nuevaBusqueda: string) {
    const params: Record<string, string> = {}
    if (nuevaBusqueda) params.q = nuevaBusqueda
    if (nuevaPagina > 1) params.pagina = String(nuevaPagina)
    setCambiandoId(null)
    setSearchParams(params, { replace: true })
  }

  function irAPagina(nueva: number) {
    actualizarFiltros(nueva, busqueda)
    window.scrollTo({ top: 0 })
  }

  return (
    <section className="vehiculos">
      <header className="encabezado">
        <h1>Vehículos</h1>
        {!registrando && (
          <button
            onClick={() => {
              setAviso(null)
              setRegistrando(true)
            }}
          >
            Nuevo vehículo
          </button>
        )}
      </header>

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

      {vehiculos.isPending && <p className="estado">Cargando vehículos…</p>}
      {vehiculos.isError && (
        <p className="error" role="alert">
          {errorMessage(vehiculos.error, 'No se pudieron cargar los vehículos.')}
        </p>
      )}

      {vehiculos.data?.vehiculos.length === 0 && (
        <p className="estado">
          {q ? `No hay vehículos que coincidan con “${q}”.` : 'Todavía no hay vehículos registrados.'}
        </p>
      )}

      {vehiculos.data && vehiculos.data.vehiculos.length > 0 && (
        <ul className="lista" aria-busy={vehiculos.isPlaceholderData}>
          {vehiculos.data.vehiculos.map((vehiculo) => (
            <li key={vehiculo.id} className="tarjeta item item-vehiculo">
              <div className="item-datos">
                <strong className="patente">{vehiculo.patente}</strong>
                {descripcion(vehiculo) && <span>{descripcion(vehiculo)}</span>}
                {vehiculo.kilometraje !== null && (
                  <span>{vehiculo.kilometraje.toLocaleString('es-AR')} km</span>
                )}
                <span>
                  Dueño: {vehiculo.cliente.nombre} ·{' '}
                  <a href={`tel:${vehiculo.cliente.telefono}`}>{vehiculo.cliente.telefono}</a>
                </span>
              </div>
              {cambiandoId === vehiculo.id ? (
                <CambiarDuenioForm
                  vehiculo={vehiculo}
                  onListo={(actualizado) => {
                    setCambiandoId(null)
                    setAviso(`${actualizado.patente} ahora es de ${actualizado.cliente.nombre}.`)
                  }}
                  onCancelar={() => setCambiandoId(null)}
                />
              ) : (
                <button
                  className="secundario"
                  onClick={() => {
                    setAviso(null)
                    setCambiandoId(vehiculo.id)
                  }}
                >
                  Cambiar dueño
                </button>
              )}
            </li>
          ))}
        </ul>
      )}

      {vehiculos.data && (
        <Paginacion
          meta={vehiculos.data.meta}
          cargando={vehiculos.isPlaceholderData}
          onCambiar={irAPagina}
        />
      )}
    </section>
  )
}
