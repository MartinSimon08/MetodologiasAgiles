import { SelectorBuscable } from '../../components/SelectorBuscable'
import { listarClientes, type Cliente } from './api'

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
      textos={{
        cargando: 'Cargando clientes…',
        sinResultados: 'Ningún cliente coincide con la búsqueda.',
        error: 'No se pudieron cargar los clientes.',
      }}
    />
  )
}
