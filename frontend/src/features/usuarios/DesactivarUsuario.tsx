import { useMutation, useQueryClient } from '@tanstack/react-query'
import { errorMessage, fieldErrors } from '../../lib/api'
import { desactivarUsuario, type UsuarioDesactivado, type UsuarioListado } from './api'

interface Props {
  usuario: UsuarioListado
  esActual: boolean
  onListo: (resultado: UsuarioDesactivado) => void
  onCancelar: () => void
}

export function DesactivarUsuario({ usuario, esActual, onListo, onCancelar }: Props) {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn: () => desactivarUsuario(usuario.id),
    onSuccess: (resultado) => {
      queryClient.invalidateQueries({ queryKey: ['usuarios'] })
      onListo(resultado)
    },
  })

  const errores = fieldErrors(mutation.error).base

  return (
    <div className="formulario reseteo" role="group" aria-label={`Desactivar a ${usuario.nombre}`}>
      <p>
        ¿Desactivar a <strong>{usuario.nombre}</strong>? No va a poder ingresar y se cierran sus sesiones abiertas. Su
        historial de tareas se conserva.
      </p>
      {usuario.tareas_en_curso > 0 && (
        <p className="advertencia" role="alert">
          Tiene {usuario.tareas_en_curso === 1 ? '1 tarea tomada' : `${usuario.tareas_en_curso} tareas tomadas`} sin
          terminar. Al desactivarlo {usuario.tareas_en_curso === 1 ? 'se libera' : 'se liberan'} para que otro mecánico
          {usuario.tareas_en_curso === 1 ? ' la tome' : ' las tome'}.
        </p>
      )}
      {esActual && <p className="advertencia">Es tu propio usuario: vas a salir del sistema.</p>}
      {mutation.isError && (
        <p className="error" role="alert">
          {errores?.join('. ') ?? errorMessage(mutation.error)}
        </p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={onCancelar}>
          Cancelar
        </button>
        <button type="button" className="peligro" disabled={mutation.isPending} onClick={() => mutation.mutate()}>
          {mutation.isPending ? 'Desactivando…' : 'Desactivar'}
        </button>
      </div>
    </div>
  )
}
