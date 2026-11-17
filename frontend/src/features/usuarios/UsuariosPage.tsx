import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { BotonNuevo } from '../../components/BotonNuevo'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { useAuth } from '../auth/AuthContext'
import { ROL_LABELS } from '../auth/types'
import { listarUsuarios, type UsuarioDesactivado, type UsuarioListado } from './api'
import { DesactivarUsuario } from './DesactivarUsuario'
import { NuevoUsuarioForm } from './NuevoUsuarioForm'
import { ResetearPasswordForm } from './ResetearPasswordForm'
import { Cargando } from '../../components/Cargando'
import { Dialogo } from '../../components/Dialogo'
import { MenuAcciones } from '../../components/MenuAcciones'
import { Tabla } from '../../components/Tabla'

export function UsuariosPage() {
  const { usuario: actual } = useAuth()
  const [creando, setCreando] = useState(false)
  const [accion, setAccion] = useState<{ tipo: 'resetear' | 'desactivar'; usuario: UsuarioListado } | null>(null)
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

  function iniciar(tipo: 'resetear' | 'desactivar', usuario: UsuarioListado) {
    setAviso(null)
    setAccion({ tipo, usuario })
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
      <EncabezadoPagina titulo="Usuarios" bajada="Personas con acceso al sistema y su rol.">
        {!creando && (
          <BotonNuevo
            onClick={() => {
              setAviso(null)
              setCreando(true)
            }}
          >
            Nuevo usuario
          </BotonNuevo>
        )}
      </EncabezadoPagina>

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

      {usuarios.isPending && <Cargando />}
      {usuarios.isError && (
        <p className="error" role="alert">
          {errorMessage(usuarios.error, 'No se pudieron cargar los usuarios.')}
        </p>
      )}

      {usuarios.data && (
        <Tabla etiqueta="Usuarios" ocupada={usuarios.isPlaceholderData}>
          <thead>
            <tr>
              <th scope="col">Nombre</th>
              <th scope="col">Email</th>
              <th scope="col">Rol</th>
              <th scope="col">Estado</th>
              <th scope="col" className="acciones-celda">
                <span className="solo-lectores">Acciones</span>
              </th>
            </tr>
          </thead>
          <tbody>
            {usuarios.data.usuarios.map((usuario) => (
              <tr key={usuario.id} className={usuario.activo ? undefined : 'inactiva'}>
                <td>
                  <strong>{usuario.nombre}</strong>
                  {usuario.id === actual?.id && ' (vos)'}
                </td>
                <td>{usuario.email}</td>
                <td>
                  <span className={`rol rol-${usuario.rol}`}>{ROL_LABELS[usuario.rol]}</span>
                </td>
                <td>
                  {usuario.activo ? (
                    'Activo'
                  ) : (
                    <span className="insignia insignia-desactivado">Desactivado</span>
                  )}
                </td>
                <td className="acciones-celda">
                  {usuario.activo && (
                    <MenuAcciones
                      etiqueta={`Acciones para ${usuario.nombre}`}
                      acciones={[
                        { etiqueta: 'Resetear contraseña', onSeleccionar: () => iniciar('resetear', usuario) },
                        { etiqueta: 'Desactivar', peligro: true, onSeleccionar: () => iniciar('desactivar', usuario) },
                      ]}
                    />
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </Tabla>
      )}

      {accion && (
        <Dialogo onCerrar={() => setAccion(null)}>
          <div className="tarjeta">
            {accion.tipo === 'resetear' ? (
              <>
                <h2>Resetear contraseña</h2>
                <ResetearPasswordForm
                  usuario={accion.usuario}
                  onListo={() => {
                    setAccion(null)
                    setAviso(`Se actualizó la contraseña de ${accion.usuario.nombre}.`)
                  }}
                  onCancelar={() => setAccion(null)}
                />
              </>
            ) : (
              <>
                <h2>Desactivar usuario</h2>
                <DesactivarUsuario
                  usuario={accion.usuario}
                  esActual={accion.usuario.id === actual?.id}
                  onListo={avisarDesactivacion}
                  onCancelar={() => setAccion(null)}
                />
              </>
            )}
          </div>
        </Dialogo>
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
