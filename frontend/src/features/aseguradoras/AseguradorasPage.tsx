import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { BotonNuevo } from '../../components/BotonNuevo'
import { Buscador } from '../../components/Buscador'
import { Cargando } from '../../components/Cargando'
import { Dialogo } from '../../components/Dialogo'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { EstadoVacio } from '../../components/EstadoVacio'
import { MenuAcciones } from '../../components/MenuAcciones'
import { Paginacion } from '../../components/Paginacion'
import { Tabla } from '../../components/Tabla'
import { errorMessage, fieldErrors } from '../../lib/api'
import { useDebounce } from '../../lib/useDebounce'
import { AseguradoraForm } from './AseguradoraForm'
import {
  cambiarEstadoAseguradora,
  eliminarAseguradora,
  listarAseguradoras,
  type Aseguradora,
} from './api'

export function AseguradorasPage() {
  const queryClient = useQueryClient()
  const [editando, setEditando] = useState<Aseguradora | null | undefined>(undefined)
  const [aviso, setAviso] = useState<string | null>(null)
  const [busqueda, setBusqueda] = useState('')
  const [pagina, setPagina] = useState(1)
  const buscar = useDebounce(busqueda.trim())

  const aseguradoras = useQuery({
    queryKey: ['aseguradoras', buscar, pagina],
    queryFn: () => listarAseguradoras(buscar, pagina),
    placeholderData: keepPreviousData,
  })

  const cambiarEstado = useMutation({
    mutationFn: ({ aseguradora, activa }: { aseguradora: Aseguradora; activa: boolean }) =>
      cambiarEstadoAseguradora(aseguradora.id, activa),
    onSuccess: async (actualizada) => {
      await queryClient.invalidateQueries({ queryKey: ['aseguradoras'] })
      setAviso(`Se ${actualizada.activa ? 'reactivó' : 'desactivó'} ${actualizada.nombre}.`)
    },
  })

  const eliminar = useMutation({
    mutationFn: (aseguradora: Aseguradora) => eliminarAseguradora(aseguradora.id),
    onSuccess: async (_, aseguradora) => {
      await queryClient.invalidateQueries({ queryKey: ['aseguradoras'] })
      setAviso(`Se eliminó ${aseguradora.nombre}.`)
    },
  })

  const ocupado = editando !== undefined || cambiarEstado.isPending || eliminar.isPending
  const errorAccion = cambiarEstado.error ?? eliminar.error

  function iniciar() {
    setAviso(null)
    cambiarEstado.reset()
    eliminar.reset()
  }

  function confirmarEliminacion(aseguradora: Aseguradora) {
    if (!window.confirm(`¿Eliminar "${aseguradora.nombre}"? Si tiene casos asociados, desactivala en su lugar.`)) return
    iniciar()
    eliminar.mutate(aseguradora)
  }

  return (
    <section className="aseguradoras">
      <EncabezadoPagina titulo="Aseguradoras" bajada="Compañías con las que trabaja el taller para asociarles los casos." />

      {aviso && (
        <p className="aviso" role="status">
          {aviso}
        </p>
      )}
      {errorAccion && (
        <p className="error" role="alert">
          {fieldErrors(errorAccion).base?.join('. ') ?? errorMessage(errorAccion, 'No se pudo completar la acción.')}
        </p>
      )}

      {editando === null && (
        <AseguradoraForm
          key="nueva"
          onCancelar={() => setEditando(undefined)}
          onGuardada={(guardada) => {
            setEditando(undefined)
            setAviso(`Se guardó ${guardada.nombre}.`)
          }}
        />
      )}

      <Buscador
        etiqueta="Buscar aseguradora"
        placeholder="Nombre de la aseguradora"
        valor={busqueda}
        onCambiar={(valor) => {
          setBusqueda(valor)
          setPagina(1)
        }}
        accion={
          editando === undefined ? (
            <BotonNuevo
              disabled={ocupado}
              onClick={() => {
                iniciar()
                setEditando(null)
              }}
            >
              Nueva aseguradora
            </BotonNuevo>
          ) : undefined
        }
      />

      {aseguradoras.isPending && <Cargando />}
      {aseguradoras.isError && (
        <p className="error" role="alert">
          {errorMessage(aseguradoras.error, 'No se pudieron cargar las aseguradoras.')}
        </p>
      )}

      {aseguradoras.data?.aseguradoras.length === 0 &&
        (buscar ? (
          <EstadoVacio busqueda titulo="Sin resultados" descripcion="No hay aseguradoras que coincidan." />
        ) : (
          <EstadoVacio
            titulo="Todavía no hay aseguradoras"
            descripcion="Cargá las compañías con las que trabaja el taller para asociarles los casos."
          />
        ))}

      {aseguradoras.data && aseguradoras.data.aseguradoras.length > 0 && (
        <>
          <Tabla etiqueta="Aseguradoras" ocupada={aseguradoras.isPlaceholderData}>
            <thead>
              <tr>
                <th scope="col">Nombre</th>
                <th scope="col">Teléfono</th>
                <th scope="col">Email</th>
                <th scope="col">Estado</th>
                <th scope="col" className="acciones-celda">
                  <span className="solo-lectores">Acciones</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {aseguradoras.data.aseguradoras.map((aseguradora) => (
                <tr key={aseguradora.id} className={aseguradora.activa ? undefined : 'inactiva'}>
                  <td>
                    <strong>{aseguradora.nombre}</strong>
                  </td>
                  <td>{aseguradora.telefono || <span className="sin-dato">—</span>}</td>
                  <td>{aseguradora.email || <span className="sin-dato">—</span>}</td>
                  <td>
                    {aseguradora.activa ? (
                      'Activa'
                    ) : (
                      <span className="insignia insignia-desactivado">Desactivada</span>
                    )}
                  </td>
                  <td className="acciones-celda">
                    <MenuAcciones
                      etiqueta={`Acciones para ${aseguradora.nombre}`}
                      acciones={[
                        {
                          etiqueta: 'Editar',
                          deshabilitada: ocupado,
                          onSeleccionar: () => {
                            iniciar()
                            setEditando(aseguradora)
                          },
                        },
                        {
                          etiqueta: aseguradora.activa ? 'Desactivar' : 'Reactivar',
                          deshabilitada: ocupado,
                          onSeleccionar: () => {
                            iniciar()
                            cambiarEstado.mutate({ aseguradora, activa: !aseguradora.activa })
                          },
                        },
                        {
                          etiqueta: 'Eliminar',
                          peligro: true,
                          deshabilitada: ocupado,
                          onSeleccionar: () => confirmarEliminacion(aseguradora),
                        },
                      ]}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </Tabla>
          <Paginacion meta={aseguradoras.data.meta} cargando={aseguradoras.isPlaceholderData} onCambiar={setPagina} />
        </>
      )}

      {editando && (
        <Dialogo onCerrar={() => setEditando(undefined)}>
          <AseguradoraForm
            key={editando.id}
            aseguradora={editando}
            onCancelar={() => setEditando(undefined)}
            onGuardada={(guardada) => {
              setEditando(undefined)
              setAviso(`Se guardó ${guardada.nombre}.`)
            }}
          />
        </Dialogo>
      )}
    </section>
  )
}
