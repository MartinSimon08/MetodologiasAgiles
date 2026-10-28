import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { BotonNuevo } from '../../components/BotonNuevo'
import { Buscador } from '../../components/Buscador'
import { Cargando } from '../../components/Cargando'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { Paginacion } from '../../components/Paginacion'
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
      <EncabezadoPagina titulo="Aseguradoras" bajada="Compañías con las que trabaja el taller para asociarles los casos.">
        {editando === undefined && (
          <BotonNuevo
            disabled={ocupado}
            onClick={() => {
              iniciar()
              setEditando(null)
            }}
          >
            Nueva aseguradora
          </BotonNuevo>
        )}
      </EncabezadoPagina>

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

      {editando !== undefined && (
        <AseguradoraForm
          key={editando?.id ?? 'nueva'}
          aseguradora={editando ?? undefined}
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
      />

      {aseguradoras.isPending && <Cargando />}
      {aseguradoras.isError && (
        <p className="error" role="alert">
          {errorMessage(aseguradoras.error, 'No se pudieron cargar las aseguradoras.')}
        </p>
      )}

      {aseguradoras.data?.aseguradoras.length === 0 && (
        <p className="estado">
          {buscar ? 'No hay aseguradoras que coincidan.' : 'Todavía no hay aseguradoras cargadas.'}
        </p>
      )}

      {aseguradoras.data && aseguradoras.data.aseguradoras.length > 0 && (
        <>
          <ul className="lista" aria-busy={aseguradoras.isPlaceholderData}>
            {aseguradoras.data.aseguradoras.map((aseguradora) => (
              <li key={aseguradora.id} className={`tarjeta item${aseguradora.activa ? '' : ' inactivo'}`}>
                <div className="item-datos">
                  <strong>{aseguradora.nombre}</strong>
                  <span>
                    {[aseguradora.telefono, aseguradora.email].filter(Boolean).join(' · ') || 'Sin contacto cargado'}
                  </span>
                </div>
                {!aseguradora.activa && <span className="insignia insignia-desactivado">Desactivada</span>}
                <div className="item-acciones">
                  <button
                    type="button"
                    className="secundario"
                    disabled={ocupado}
                    onClick={() => {
                      iniciar()
                      setEditando(aseguradora)
                    }}
                    aria-label={`Editar ${aseguradora.nombre}`}
                  >
                    Editar
                  </button>
                  <button
                    type="button"
                    className={aseguradora.activa ? 'secundario peligro' : 'secundario'}
                    disabled={ocupado}
                    onClick={() => {
                      iniciar()
                      cambiarEstado.mutate({ aseguradora, activa: !aseguradora.activa })
                    }}
                    aria-label={`${aseguradora.activa ? 'Desactivar' : 'Reactivar'} ${aseguradora.nombre}`}
                  >
                    {aseguradora.activa ? 'Desactivar' : 'Reactivar'}
                  </button>
                  <button
                    type="button"
                    className="peligro"
                    disabled={ocupado}
                    onClick={() => confirmarEliminacion(aseguradora)}
                    aria-label={`Eliminar ${aseguradora.nombre}`}
                  >
                    Eliminar
                  </button>
                </div>
              </li>
            ))}
          </ul>
          <Paginacion meta={aseguradoras.data.meta} cargando={aseguradoras.isPlaceholderData} onCambiar={setPagina} />
        </>
      )}
    </section>
  )
}
