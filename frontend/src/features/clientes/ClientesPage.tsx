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
import { EstadoVacio } from '../../components/EstadoVacio'
import { Tabla } from '../../components/Tabla'
import { Cargando } from '../../components/Cargando'
import { usePorPagina } from '../../lib/paginacion'

export function ClientesPage() {
  const [registrando, setRegistrando] = useState(false)
  const [aviso, setAviso] = useState<string | null>(null)

  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)
  const [porPagina, setPorPagina] = usePorPagina()
  const busqueda = searchParams.get('q') ?? ''
  const q = useDebounce(busqueda.trim())

  const clientes = useQuery({
    queryKey: ['clientes', pagina, q, porPagina],
    queryFn: () => listarClientes(pagina, q, porPagina),
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

  const nuevo = !registrando && (
    <BotonNuevo
      onClick={() => {
        setAviso(null)
        setRegistrando(true)
      }}
    >
      Nuevo cliente
    </BotonNuevo>
  )

  return (
    <section className="clientes">
      <EncabezadoPagina titulo="Clientes" bajada="Personas que traen vehículos al taller.">
        {nuevo}
      </EncabezadoPagina>

      {aviso && (
        <p className="aviso" role="status">
          {aviso}
        </p>
      )}

      {registrando && (
        <NuevoClienteForm
          onRegistrado={(cliente) => {
            setRegistrando(false)
            setAviso(`Se registró a ${cliente.nombre}.`)
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

      {clientes.isPending && <Cargando />}
      {clientes.isError && (
        <p className="error" role="alert">
          {errorMessage(clientes.error, 'No se pudieron cargar los clientes.')}
        </p>
      )}

      {clientes.data?.clientes.length === 0 &&
        (q ? (
          <EstadoVacio
            busqueda
            titulo="Sin resultados"
            descripcion={`No hay clientes que coincidan con “${q}”.`}
          />
        ) : (
          <EstadoVacio
            titulo="Todavía no hay clientes"
            descripcion="Registrá al primer cliente para poder ingresar su vehículo."
          />
        ))}

      {clientes.data && clientes.data.clientes.length > 0 && (
        <Tabla etiqueta="Clientes" ocupada={clientes.isPlaceholderData}>
          <thead>
            <tr>
              <th scope="col">Nombre</th>
              <th scope="col">Teléfono</th>
              <th scope="col">Email</th>
            </tr>
          </thead>
          <tbody>
            {clientes.data.clientes.map((cliente) => (
              <tr key={cliente.id}>
                <td>
                  <strong>{cliente.nombre}</strong>
                </td>
                <td>
                  <a href={`tel:${cliente.telefono}`}>{cliente.telefono}</a>
                </td>
                <td>{cliente.email ?? <span className="sin-dato">—</span>}</td>
              </tr>
            ))}
          </tbody>
        </Tabla>
      )}

      {clientes.data && (
        <Paginacion
          meta={clientes.data.meta}
          cargando={clientes.isPlaceholderData}
          onCambiar={irAPagina}
          porPagina={porPagina}
          onCambiarPorPagina={(valor) => {
            setPorPagina(valor)
            irAPagina(1)
          }}
        />
      )}
    </section>
  )
}
