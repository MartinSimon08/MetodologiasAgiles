import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
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

  const usuarios = useQuery({ queryKey: ['usuarios'], queryFn: listarUsuarios })

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
        <ul className="lista">
          {usuarios.data.map((usuario) => (
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
    </section>
  )
}
