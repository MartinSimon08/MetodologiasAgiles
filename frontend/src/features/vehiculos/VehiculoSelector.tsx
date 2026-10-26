import { SelectorBuscable, type FormularioCreacion } from '../../components/SelectorBuscable'
import { listarVehiculos, type Vehiculo } from './api'
import { NuevoVehiculoForm } from './NuevoVehiculoForm'

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

function detalle(vehiculo: Vehiculo) {
  return [vehiculo.marca, vehiculo.modelo].filter(Boolean).join(' ')
}

function FormularioNuevoVehiculo({ onCreado, onCancelar, onBuscar }: FormularioCreacion<Vehiculo>) {
  return <NuevoVehiculoForm onRegistrado={onCreado} onVerExistente={onBuscar} onCancelar={onCancelar} />
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
          <strong>
            <span className="patente">{vehiculo.patente}</span>
            {detalle(vehiculo) ? ` ${detalle(vehiculo)}` : ''}
          </strong>
          <span>{vehiculo.cliente.nombre}</span>
        </>
      )}
      crear={{
        etiqueta: 'Nuevo vehículo',
        Formulario: FormularioNuevoVehiculo,
      }}
      textos={{
        cargando: 'Cargando vehículos…',
        sinResultados: 'Ningún vehículo coincide con la búsqueda.',
        error: 'No se pudieron cargar los vehículos.',
      }}
    />
  )
}
