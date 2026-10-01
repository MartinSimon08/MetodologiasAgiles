import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Buscador } from '../../components/Buscador'
import { ErroresCampo } from '../../components/ErroresCampo'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { useDebounce } from '../../lib/useDebounce'
import { listarClientes } from './api'

interface Props {
  etiqueta: string
  valor: number | null
  onCambiar: (clienteId: number | null) => void
  excluirId?: number
  errores?: string[]
  autoFocus?: boolean
}

export function ClienteSelector({ etiqueta, valor, onCambiar, excluirId, errores, autoFocus }: Props) {
  const [pagina, setPagina] = useState(1)
  const [busqueda, setBusqueda] = useState('')
  const q = useDebounce(busqueda.trim())

  const clientes = useQuery({
    queryKey: ['clientes', pagina, q],
    queryFn: () => listarClientes(pagina, q),
    placeholderData: keepPreviousData,
  })

  const opciones = clientes.data?.clientes.filter((cliente) => cliente.id !== excluirId) ?? []

  return (
    <div className="selector-cliente">
      <Buscador
        etiqueta="Buscar cliente"
        autoFocus={autoFocus}
        placeholder="Nombre, teléfono o patente"
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
          disabled={clientes.isPending}
          required
        >
          <option value="">
            {clientes.isPending
              ? 'Cargando clientes…'
              : opciones.length === 0
                ? q
                  ? 'Ningún cliente coincide con la búsqueda'
                  : 'No hay clientes para elegir'
                : 'Elegí un cliente'}
          </option>
          {opciones.map((cliente) => (
            <option key={cliente.id} value={cliente.id}>
              {cliente.nombre} · {cliente.telefono}
            </option>
          ))}
        </select>
        <ErroresCampo errores={errores} />
      </label>
      {clientes.isError && (
        <span className="error">{errorMessage(clientes.error, 'No se pudieron cargar los clientes.')}</span>
      )}
      {clientes.data && (
        <Paginacion
          meta={clientes.data.meta}
          cargando={clientes.isPlaceholderData}
          onCambiar={(nueva) => {
            onCambiar(null)
            setPagina(nueva)
          }}
        />
      )}
    </div>
  )
}
