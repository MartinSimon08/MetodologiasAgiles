import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
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

  const clientes = useQuery({
    queryKey: ['clientes', pagina],
    queryFn: () => listarClientes(pagina),
    placeholderData: keepPreviousData,
  })

  const opciones = clientes.data?.clientes.filter((cliente) => cliente.id !== excluirId) ?? []

  return (
    <div className="selector-cliente">
      <label>
        {etiqueta}
        <select
          autoFocus={autoFocus}
          value={valor ?? ''}
          onChange={(e) => onCambiar(e.target.value ? Number(e.target.value) : null)}
          disabled={clientes.isPending}
          required
        >
          <option value="">
            {clientes.isPending
              ? 'Cargando clientes…'
              : opciones.length === 0
                ? 'No hay clientes para elegir'
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
