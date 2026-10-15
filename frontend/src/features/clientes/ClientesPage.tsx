import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { BotonNuevo } from '../../components/BotonNuevo'
import { Buscador } from '../../components/Buscador'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { useDebounce } from '../../lib/useDebounce'
import { listarClientes } from './api'
import { NuevoClienteForm } from './NuevoClienteForm'

export function ClientesPage() {
  const [registrando, setRegistrando] = useState(false)
  const [aviso, setAviso] = useState<string | null>(null)

  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)
  const busqueda = searchParams.get('q') ?? ''
  const q = useDebounce(busqueda.trim())

  const clientes = useQuery({
    queryKey: ['clientes', pagina, q],
    queryFn: () => listarClientes(pagina, q),
    placeholderData: keepPreviousData,
  })

  function actualizarFiltros(nuevaPagina: number, nuevaBusqueda: string) {
    const params: Record<string, string> = {}
    if (nuevaBusqueda) params.q = nuevaBusqueda
    if (nuevaPagina > 1) params.pagina = String(nuevaPagina)
    setSearchParams(params, { replace: true })
  }

  function irAPagina(nueva: number) {
    actualizarFiltros(nueva, busqueda)
    window.scrollTo({ top: 0 })
  }

  return (
    <section className="clientes">
      <EncabezadoPagina titulo="Clientes" bajada="Personas que traen vehículos al taller.">
        {!registrando && (
          <BotonNuevo
            onClick={() => {
              setAviso(null)
              setRegistrando(true)
            }}
          >
            Nuevo cliente
          </BotonNuevo>
        )}
      </EncabezadoPagina>

      {aviso && (
        <p className="aviso" role="status">
          {aviso}
        </p>
      )}

      {registrando && (
        <NuevoClienteForm
          onRegistrado={(nombre) => {
            setRegistrando(false)
            setAviso(`Se registró a ${nombre}.`)
          }}
          onCancelar={() => setRegistrando(false)}
        />
      )}

      <Buscador
        etiqueta="Buscar cliente"
        placeholder="Nombre, teléfono o patente"
        valor={busqueda}
        onCambiar={(valor) => actualizarFiltros(1, valor)}
      />

      {clientes.isPending && <p className="estado">Cargando clientes…</p>}
      {clientes.isError && (
        <p className="error" role="alert">
          {errorMessage(clientes.error, 'No se pudieron cargar los clientes.')}
        </p>
      )}

      {clientes.data?.clientes.length === 0 && (
        <p className="vacio">
          {q ? `No hay clientes que coincidan con “${q}”.` : 'Todavía no hay clientes registrados.'}
        </p>
      )}

      {clientes.data && clientes.data.clientes.length > 0 && (
        <ul className="lista" aria-busy={clientes.isPlaceholderData}>
          {clientes.data.clientes.map((cliente) => (
            <li key={cliente.id} className="tarjeta fila-item">
              <div className="item-datos">
                <strong>{cliente.nombre}</strong>
                <span>
                  <a href={`tel:${cliente.telefono}`}>{cliente.telefono}</a>
                  {cliente.email && ` · ${cliente.email}`}
                </span>
              </div>
            </li>
          ))}
        </ul>
      )}

      {clientes.data && (
        <Paginacion
          meta={clientes.data.meta}
          cargando={clientes.isPlaceholderData}
          onCambiar={irAPagina}
        />
      )}
    </section>
  )
}
