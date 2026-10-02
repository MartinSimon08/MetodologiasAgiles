import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Buscador } from '../../components/Buscador'
import { ErroresCampo } from '../../components/ErroresCampo'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { useDebounce } from '../../lib/useDebounce'
import { listarVehiculos, type Vehiculo } from './api'

interface Props {
  etiqueta: string
  valor: number | null
  onCambiar: (vehiculoId: number | null) => void
  errores?: string[]
  autoFocus?: boolean
}

function opcion(vehiculo: Vehiculo) {
  return [vehiculo.patente, [vehiculo.marca, vehiculo.modelo].filter(Boolean).join(' '), vehiculo.cliente.nombre]
    .filter(Boolean)
    .join(' · ')
}

export function VehiculoSelector({ etiqueta, valor, onCambiar, errores, autoFocus }: Props) {
  const [pagina, setPagina] = useState(1)
  const [busqueda, setBusqueda] = useState('')
  const q = useDebounce(busqueda.trim())

  const vehiculos = useQuery({
    queryKey: ['vehiculos', pagina, q],
    queryFn: () => listarVehiculos(pagina, q),
    placeholderData: keepPreviousData,
  })

  const opciones = vehiculos.data?.vehiculos ?? []

  return (
    <div className="selector-vehiculo">
      <Buscador
        etiqueta="Buscar vehículo"
        autoFocus={autoFocus}
        placeholder="Patente, nombre o teléfono del dueño"
        valor={busqueda}
        onCambiar={(valor) => {
          onCambiar(null)
          setPagina(1)
          setBusqueda(valor)
        }}
      />
      <label>
        {etiqueta}
        <select
          value={valor ?? ''}
          onChange={(e) => onCambiar(e.target.value ? Number(e.target.value) : null)}
          disabled={vehiculos.isPending}
          required
        >
          <option value="">
            {vehiculos.isPending
              ? 'Cargando vehículos…'
              : opciones.length === 0
                ? q
                  ? 'Ningún vehículo coincide con la búsqueda'
                  : 'No hay vehículos para elegir'
                : 'Elegí un vehículo'}
          </option>
          {opciones.map((vehiculo) => (
            <option key={vehiculo.id} value={vehiculo.id}>
              {opcion(vehiculo)}
            </option>
          ))}
        </select>
        <ErroresCampo errores={errores} />
      </label>
      {vehiculos.isError && (
        <span className="error">{errorMessage(vehiculos.error, 'No se pudieron cargar los vehículos.')}</span>
      )}
      {vehiculos.data && (
        <Paginacion
          meta={vehiculos.data.meta}
          cargando={vehiculos.isPlaceholderData}
          onCambiar={(nueva) => {
            onCambiar(null)
            setPagina(nueva)
          }}
        />
      )}
    </div>
  )
}
