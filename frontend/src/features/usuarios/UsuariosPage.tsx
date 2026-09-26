import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { useAuth } from '../auth/AuthContext'
import { ROL_LABELS } from '../auth/types'
import { listarUsuarios } from './api'
import { NuevoUsuarioForm } from './NuevoUsuarioForm'
import { ResetearPasswordForm } from './ResetearPasswordForm'

export function UsuariosPage() {
  const { usuario: actual } = useAuth()
  const [creando, setCreando] = useState(false)
  const [reseteandoId, setReseteandoId] = useState<number | null>(null)
  const [aviso, setAviso] = useState<string | null>(null)

  const [searchParams, setSearchParams] = useSearchParams()
  const pagina = Math.max(1, Number(searchParams.get('pagina')) || 1)

  const usuarios = useQuery({
    queryKey: ['usuarios', pagina],
    queryFn: () => listarUsuarios(pagina),
    placeholderData: keepPreviousData,
  })

  function irAPagina(nueva: number) {
    setReseteandoId(null)
    setSearchParams(nueva === 1 ? {} : { pagina: String(nueva) })
    window.scrollTo({ top: 0 })
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
            <li key={usuario.id} className="tarjeta item">
              <div className="item-datos">
                <strong>
                  {usuario.nombre}
                  {usuario.id === actual?.id && ' (vos)'}
                </strong>
                <span>{usuario.email}</span>
              </div>
              <span className={`rol rol-${usuario.rol}`}>{ROL_LABELS[usuario.rol]}</span>
              {reseteandoId === usuario.id ? (
                <ResetearPasswordForm
                  usuario={usuario}
                  onListo={() => {
                    setReseteandoId(null)
                    setAviso(`Se actualizó la contraseña de ${usuario.nombre}.`)
                  }}
                  onCancelar={() => setReseteandoId(null)}
                />
              ) : (
                <button
                  className="secundario"
                  onClick={() => {
                    setAviso(null)
                    setReseteandoId(usuario.id)
                  }}
                >
                  Resetear contraseña
                </button>
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
