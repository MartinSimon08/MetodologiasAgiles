import { SelectorBuscable, type FormularioCreacion } from '../../components/SelectorBuscable'
import { listarClientes, type Cliente } from './api'
import { NuevoClienteForm } from './NuevoClienteForm'

interface Props {
  etiqueta: string
  valor: number | null
  onCambiar: (clienteId: number | null) => void
  excluirId?: number
  errores?: string[]
  autoFocus?: boolean
}

async function cargar(pagina: number, q: string) {
  const { clientes, meta } = await listarClientes(pagina, q)
  return { items: clientes, meta }
}

function FormularioNuevoCliente({ onCreado, onCancelar }: FormularioCreacion<Cliente>) {
  return <NuevoClienteForm onRegistrado={onCreado} onCancelar={onCancelar} />
}

export function ClienteSelector(props: Props) {
  return (
    <SelectorBuscable<Cliente>
      {...props}
      placeholder="Nombre, teléfono o patente"
      queryKey="clientes"
      cargar={cargar}
      describir={(cliente) => (
        <>
          <strong>{cliente.nombre}</strong>
          <span>{cliente.telefono}</span>
        </>
      )}
      crear={{
        etiqueta: 'Nuevo cliente',
        Formulario: FormularioNuevoCliente,
      }}
      textos={{
        cargando: 'Cargando clientes…',
        sinResultados: 'Ningún cliente coincide con la búsqueda.',
        error: 'No se pudieron cargar los clientes.',
      }}
    />
  )
}
