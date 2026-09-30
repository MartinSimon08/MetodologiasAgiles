import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { useAuth } from '../auth/AuthContext'
import { ROL_LABELS } from '../auth/types'
import { listarUsuarios, type UsuarioDesactivado } from './api'
import { DesactivarUsuario } from './DesactivarUsuario'
import { NuevoUsuarioForm } from './NuevoUsuarioForm'
import { ResetearPasswordForm } from './ResetearPasswordForm'

export function UsuariosPage() {
  const { usuario: actual } = useAuth()
  const [creando, setCreando] = useState(false)
  const [accion, setAccion] = useState<{ tipo: 'resetear' | 'desactivar'; id: number } | null>(null)
  const [aviso, setAviso] = useState<string | null>(null)

  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)

  const usuarios = useQuery({
    queryKey: ['usuarios', pagina],
    queryFn: () => listarUsuarios(pagina),
    placeholderData: keepPreviousData,
  })

  function irAPagina(nueva: number) {
    setAccion(null)
    setSearchParams(nueva === 1 ? {} : { pagina: String(nueva) })
    window.scrollTo({ top: 0 })
  }

  function iniciar(tipo: 'resetear' | 'desactivar', id: number) {
    setAviso(null)
    setAccion({ tipo, id })
  }

  function avisarDesactivacion({ nombre, tareas_liberadas }: UsuarioDesactivado) {
    setAccion(null)
    const liberadas =
      tareas_liberadas.length === 0
        ? ''
        : ` Se ${tareas_liberadas.length === 1 ? 'liberó 1 tarea' : `liberaron ${tareas_liberadas.length} tareas`}: ${tareas_liberadas
            .map((tarea) => `${tarea.descripcion} (orden #${tarea.orden_id})`)
            .join(', ')}.`
    setAviso(`Se desactivó a ${nombre}.${liberadas}`)
  }

  return (
    <section className="usuarios">
      <header className="encabezado">
        <h1>Usuarios</h1>
        {!creando && (
          <button
            onClick={() => {
              setAviso(null)
              setCreando(true)
            }}
          >
            Nuevo usuario
          </button>
        )}
      </header>

      {aviso && (
        <p className="aviso" role="status">
          {aviso}
        </p>
      )}

      {creando && (
        <NuevoUsuarioForm
          onCreado={(nombre) => {
            setCreando(false)
            setAviso(`Se creó el usuario de ${nombre}.`)
          }}
          onCancelar={() => setCreando(false)}
        />
      )}

      {usuarios.isPending && <p className="estado">Cargando usuarios…</p>}
      {usuarios.isError && (
        <p className="error" role="alert">
          {errorMessage(usuarios.error, 'No se pudieron cargar los usuarios.')}
        </p>
      )}

      {usuarios.data && (
        <ul className="lista" aria-busy={usuarios.isPlaceholderData}>
          {usuarios.data.usuarios.map((usuario) => (
            <li key={usuario.id} className={`tarjeta item${usuario.activo ? '' : ' inactivo'}`}>
              <div className="item-datos">
                <strong>
                  {usuario.nombre}
                  {usuario.id === actual?.id && ' (vos)'}
                </strong>
                <span>{usuario.email}</span>
              </div>
              <span className={`rol rol-${usuario.rol}`}>{ROL_LABELS[usuario.rol]}</span>
              {!usuario.activo ? (
                <span className="insignia insignia-desactivado">Desactivado</span>
              ) : accion?.id === usuario.id && accion.tipo === 'resetear' ? (
                <ResetearPasswordForm
                  usuario={usuario}
                  onListo={() => {
                    setAccion(null)
                    setAviso(`Se actualizó la contraseña de ${usuario.nombre}.`)
                  }}
                  onCancelar={() => setAccion(null)}
                />
              ) : accion?.id === usuario.id && accion.tipo === 'desactivar' ? (
                <DesactivarUsuario
                  usuario={usuario}
                  esActual={usuario.id === actual?.id}
                  onListo={avisarDesactivacion}
                  onCancelar={() => setAccion(null)}
                />
              ) : (
                <div className="item-acciones">
                  <button className="secundario" onClick={() => iniciar('resetear', usuario.id)}>
                    Resetear contraseña
                  </button>
                  <button className="secundario peligro" onClick={() => iniciar('desactivar', usuario.id)}>
                    Desactivar
                  </button>
                </div>
              )}
            </li>
          ))}
        </ul>
      )}

      {usuarios.data && (
        <Paginacion
          meta={usuarios.data.meta}
          cargando={usuarios.isPlaceholderData}
          onCambiar={irAPagina}
        />
      )}
    </section>
  )
}
