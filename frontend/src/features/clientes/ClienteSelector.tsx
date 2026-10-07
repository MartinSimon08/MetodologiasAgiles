import { useQuery } from '@tanstack/react-query'
import { useEffect, useId, useRef, useState, type KeyboardEvent } from 'react'
import { Buscador } from '../../components/Buscador'
import { ErroresCampo } from '../../components/ErroresCampo'
import { ListaSugerencias, type Sugerencia } from '../../components/ListaSugerencias'
import { errorMessage } from '../../lib/api'
import { useDebounce } from '../../lib/useDebounce'
import { listarClientes, type Cliente } from './api'

const LIMITE = 5

interface Props {
  etiqueta: string
  valor: number | null
  onCambiar: (clienteId: number | null) => void
  excluirId?: number
  errores?: string[]
  autoFocus?: boolean
}

function sugerencia(cliente: Cliente): Sugerencia {
  return { id: cliente.id, titulo: cliente.nombre, detalle: cliente.telefono }
}

export function ClienteSelector({ etiqueta, valor, onCambiar, excluirId, errores, autoFocus }: Props) {
  const listId = useId()
  const raiz = useRef<HTMLDivElement>(null)
  const [busqueda, setBusqueda] = useState('')
  const [abierta, setAbierta] = useState(false)
  const [activo, setActivo] = useState(0)
  const [elegido, setElegido] = useState<Sugerencia | null>(null)
  const q = useDebounce(busqueda.trim())
  const texto = busqueda.trim()
  const pendiente = abierta && texto.length > 0 && q !== texto
  const consultar = abierta && q.length > 0 && q === texto
  const pedido = excluirId ? LIMITE + 1 : LIMITE

  const clientes = useQuery({
    queryKey: ['clientes', 'sugerencias', q, pedido],
    queryFn: () => listarClientes(1, q, pedido),
    enabled: consultar,
  })

  const opciones = (clientes.data?.clientes ?? [])
    .filter((cliente) => cliente.id !== excluirId)
    .slice(0, LIMITE)
    .map(sugerencia)
  const lista = consultar && !clientes.isLoading && !clientes.isError ? opciones : []
  const indiceActivo = lista.length === 0 ? 0 : Math.min(activo, lista.length - 1)
  const seleccionado = elegido && elegido.id === valor ? elegido : null
  const mostrarLista = abierta && texto.length > 0
  const hayMas = consultar && (clientes.data?.meta.total ?? 0) > pedido

  useEffect(() => {
    if (!abierta) return
    function alClickAfuera(event: PointerEvent) {
      if (!raiz.current?.contains(event.target as Node)) setAbierta(false)
    }
    document.addEventListener('pointerdown', alClickAfuera)
    return () => document.removeEventListener('pointerdown', alClickAfuera)
  }, [abierta])

  function escribir(nuevo: string) {
    setBusqueda(nuevo)
    setElegido(null)
    setAbierta(nuevo.trim().length > 0)
    onCambiar(null)
  }

  function elegir(id: number) {
    const cliente = lista.find((opcion) => opcion.id === id)
    if (!cliente) return
    setElegido(cliente)
    setBusqueda('')
    setAbierta(false)
    onCambiar(cliente.id)
  }

  function onKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (!mostrarLista) return
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      if (lista.length === 0) return
      setActivo((indiceActivo + 1) % lista.length)
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      if (lista.length === 0) return
      setActivo((indiceActivo - 1 + lista.length) % lista.length)
    } else if (event.key === 'Enter') {
      event.preventDefault()
      if (lista[indiceActivo]) elegir(lista[indiceActivo].id)
    } else if (event.key === 'Escape') {
      setAbierta(false)
    }
  }

  return (
    <div className="selector-cliente" ref={raiz}>
      <Buscador
        etiqueta="Buscar cliente"
        autoFocus={autoFocus}
        placeholder="Nombre, teléfono o patente"
        valor={busqueda}
        controles={listId}
        expandido={lista.length > 0}
        activoId={lista.length > 0 ? `${listId}-opcion-${indiceActivo}` : undefined}
        onCambiar={escribir}
        onKeyDown={onKeyDown}
        onFocus={() => {
          if (busqueda.trim() && !elegido) setAbierta(true)
        }}
      />
      {!texto && !seleccionado && <small>Escribí para ver hasta 5 coincidencias.</small>}
      {seleccionado && (
        <p className="seleccion-actual">
          <span>{etiqueta}</span>
          <strong>{seleccionado.titulo}</strong>
          {seleccionado.detalle && <small>{seleccionado.detalle}</small>}
        </p>
      )}
      {mostrarLista && (
        <ListaSugerencias
          id={listId}
          cargando={pendiente || clientes.isLoading}
          error={
            consultar && clientes.isError ? errorMessage(clientes.error, 'No se pudieron cargar los clientes.') : null
          }
          items={lista}
          activo={indiceActivo}
          vacio={`Ningún cliente coincide con “${q}”.`}
          aviso={hayMas ? 'Hay más coincidencias. Seguí escribiendo para afinar la búsqueda.' : undefined}
          onElegir={elegir}
          onResaltar={setActivo}
        />
      )}
      <ErroresCampo errores={errores} />
    </div>
  )
}
