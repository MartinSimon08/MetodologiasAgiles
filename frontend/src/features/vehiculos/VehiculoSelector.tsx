import { useQuery } from '@tanstack/react-query'
import { useEffect, useId, useRef, useState, type KeyboardEvent } from 'react'
import { Buscador } from '../../components/Buscador'
import { ErroresCampo } from '../../components/ErroresCampo'
import { ListaSugerencias, type Sugerencia } from '../../components/ListaSugerencias'
import { errorMessage } from '../../lib/api'
import { useDebounce } from '../../lib/useDebounce'
import { listarVehiculos, type Vehiculo } from './api'

const LIMITE = 5

interface Props {
  etiqueta: string
  valor: number | null
  onCambiar: (vehiculoId: number | null) => void
  errores?: string[]
  autoFocus?: boolean
}

function sugerencia(vehiculo: Vehiculo): Sugerencia {
  const detalle = [[vehiculo.marca, vehiculo.modelo].filter(Boolean).join(' '), vehiculo.cliente.nombre]
    .filter(Boolean)
    .join(' · ')
  return { id: vehiculo.id, titulo: vehiculo.patente, detalle: detalle || undefined }
}

export function VehiculoSelector({ etiqueta, valor, onCambiar, errores, autoFocus }: Props) {
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

  const vehiculos = useQuery({
    queryKey: ['vehiculos', 'sugerencias', q],
    queryFn: () => listarVehiculos(1, q, LIMITE),
    enabled: consultar,
  })

  const opciones = (vehiculos.data?.vehiculos ?? []).slice(0, LIMITE).map(sugerencia)
  const lista = consultar && !vehiculos.isLoading && !vehiculos.isError ? opciones : []
  const indiceActivo = lista.length === 0 ? 0 : Math.min(activo, lista.length - 1)
  const seleccionado = elegido && elegido.id === valor ? elegido : null
  const mostrarLista = abierta && texto.length > 0
  const hayMas = consultar && (vehiculos.data?.meta.total ?? 0) > LIMITE

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
    const vehiculo = lista.find((opcion) => opcion.id === id)
    if (!vehiculo) return
    setElegido(vehiculo)
    setBusqueda('')
    setAbierta(false)
    onCambiar(vehiculo.id)
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
    <div className="selector-vehiculo" ref={raiz}>
      <Buscador
        etiqueta="Buscar vehículo"
        autoFocus={autoFocus}
        placeholder="Patente, nombre o teléfono del dueño"
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
          cargando={pendiente || vehiculos.isLoading}
          error={
            consultar && vehiculos.isError ? errorMessage(vehiculos.error, 'No se pudieron cargar los vehículos.') : null
          }
          items={lista}
          activo={indiceActivo}
          vacio={`Ningún vehículo coincide con “${q}”.`}
          aviso={hayMas ? 'Hay más coincidencias. Seguí escribiendo para afinar la búsqueda.' : undefined}
          onElegir={elegir}
          onResaltar={setActivo}
        />
      )}
      <ErroresCampo errores={errores} />
    </div>
  )
}
