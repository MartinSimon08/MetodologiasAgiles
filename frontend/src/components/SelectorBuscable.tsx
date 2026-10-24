import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useRef, useState, type KeyboardEvent, type ReactNode } from 'react'
import { errorMessage, type MetaPaginacion } from '../lib/api'
import { useDebounce } from '../lib/useDebounce'
import { Buscador } from './Buscador'
import { ErroresCampo } from './ErroresCampo'
import { Paginacion } from './Paginacion'

interface Props<T extends { id: number }> {
  etiqueta: string
  placeholder: string
  queryKey: string
  cargar: (pagina: number, q: string) => Promise<{ items: T[]; meta: MetaPaginacion }>
  describir: (item: T) => ReactNode
  valor: number | null
  onCambiar: (id: number | null) => void
  excluirId?: number
  errores?: string[]
  autoFocus?: boolean
  textos: { cargando: string; sinResultados: string; error: string }
}

export function SelectorBuscable<T extends { id: number }>({
  etiqueta,
  placeholder,
  queryKey,
  cargar,
  describir,
  valor,
  onCambiar,
  excluirId,
  errores,
  autoFocus,
  textos,
}: Props<T>) {
  const buscador = useRef<HTMLInputElement>(null)
  const [pagina, setPagina] = useState(1)
  const [busqueda, setBusqueda] = useState('')
  const [seleccionado, setSeleccionado] = useState<T | null>(null)
  const q = useDebounce(busqueda.trim())

  const consulta = useQuery({
    queryKey: ['selector', queryKey, pagina, q],
    queryFn: () => cargar(pagina, q),
    placeholderData: keepPreviousData,
    enabled: valor === null && q !== '',
  })

  const buscando = valor === null && q !== ''
  const opciones = (buscando && consulta.data?.items.filter((item) => item.id !== excluirId)) || []
  const elegido = valor !== null && seleccionado?.id === valor ? seleccionado : null
  const sinResultados =
    buscando && Boolean(consulta.data) && !consulta.isPending && !consulta.isPlaceholderData && opciones.length === 0

  function elegir(item: T | null) {
    setSeleccionado(item)
    onCambiar(item?.id ?? null)
    if (item === null) queueMicrotask(() => buscador.current?.focus())
  }

  function alTecla(event: KeyboardEvent<HTMLInputElement>) {
    if (event.key !== 'Enter') return
    event.preventDefault()
    if (opciones.length === 1 && !consulta.isPlaceholderData) elegir(opciones[0])
  }

  if (elegido) {
    return (
      <div className="selector">
        <span className="etiqueta-campo">{etiqueta}</span>
        <div className="seleccionado">
          <span className="item-datos">{describir(elegido)}</span>
          <button type="button" className="secundario" onClick={() => elegir(null)}>
            Cambiar
          </button>
        </div>
        <ErroresCampo errores={errores} />
      </div>
    )
  }

  return (
    <div className="selector">
      <Buscador
        etiqueta={etiqueta}
        autoFocus={autoFocus}
        placeholder={placeholder}
        valor={busqueda}
        inputRef={buscador}
        onKeyDown={alTecla}
        onCambiar={(texto) => {
          setPagina(1)
          setBusqueda(texto)
        }}
      />
      <ErroresCampo errores={errores} />
      {buscando && consulta.isPending && <p className="estado">{textos.cargando}</p>}
      {buscando && consulta.isError && (
        <p className="error" role="alert">
          {errorMessage(consulta.error, textos.error)}
        </p>
      )}
      {sinResultados && <p className="estado">{textos.sinResultados}</p>}
      {opciones.length > 0 && (
        <ul className="opciones" aria-label={etiqueta} aria-busy={consulta.isPlaceholderData}>
          {opciones.map((item) => (
            <li key={item.id}>
              <button type="button" className="opcion" onClick={() => elegir(item)}>
                <span className="item-datos">{describir(item)}</span>
                <span className="opcion-accion">Elegir</span>
              </button>
            </li>
          ))}
        </ul>
      )}
      {buscando && consulta.data && (
        <Paginacion meta={consulta.data.meta} cargando={consulta.isPlaceholderData} onCambiar={setPagina} />
      )}
    </div>
  )
}
