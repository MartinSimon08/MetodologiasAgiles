import { SelectorBuscable } from '../../components/SelectorBuscable'
import { listarVehiculos, type Vehiculo } from './api'

interface Props {
  etiqueta: string
  valor: number | null
  onCambiar: (vehiculoId: number | null) => void
  errores?: string[]
  autoFocus?: boolean
}

async function cargar(pagina: number, q: string) {
  const { vehiculos, meta } = await listarVehiculos(pagina, q)
  return { items: vehiculos, meta }
}

export function VehiculoSelector(props: Props) {
  return (
    <SelectorBuscable<Vehiculo>
      {...props}
      placeholder="Patente, nombre o teléfono del dueño"
      queryKey="vehiculos"
      cargar={cargar}
      describir={(vehiculo) => (
        <>
          <span className="vehiculo">
            <span className="patente">{vehiculo.patente}</span>
            {[vehiculo.marca, vehiculo.modelo].filter(Boolean).join(' ')}
          </span>
          <span>{vehiculo.cliente.nombre}</span>
        </>
      )}
      textos={{
        cargando: 'Cargando vehículos…',
        sinResultados: 'Ningún vehículo coincide con la búsqueda.',
        error: 'No se pudieron cargar los vehículos.',
      }}
    />
  )
}
