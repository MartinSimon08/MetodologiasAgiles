import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { errorMessage, fieldErrors } from '../../lib/api'
import { fechaHora } from '../../lib/formato'
import { useAuth } from '../auth/AuthContext'
import { cancelarOrden } from './api'
import type { Orden, OrdenCancelada } from './types'

interface Props {
  orden: Orden
}

function avisoLiberadas({ tareas_liberadas }: OrdenCancelada) {
  if (tareas_liberadas.length === 0) return null
  const descripciones = tareas_liberadas.map((tarea) => tarea.descripcion).join(', ')
  return tareas_liberadas.length === 1
    ? `Se liberó 1 tarea que estaba en curso: ${descripciones}.`
    : `Se liberaron ${tareas_liberadas.length} tareas que estaban en curso: ${descripciones}.`
}

export function CancelarOrden({ orden }: Props) {
  const { usuario } = useAuth()
  const queryClient = useQueryClient()
  const [confirmando, setConfirmando] = useState(false)
  const [liberadas, setLiberadas] = useState<string | null>(null)

  const mutation = useMutation({
    mutationFn: () => cancelarOrden(orden.id),
    onSuccess: (cancelada) => {
      setConfirmando(false)
      setLiberadas(avisoLiberadas(cancelada))
      queryClient.invalidateQueries({ queryKey: ['orden', orden.id] })
      queryClient.invalidateQueries({ queryKey: ['ordenes'] })
      queryClient.invalidateQueries({ queryKey: ['tareas', orden.id] })
    },
  })

  if (orden.estado === 'cancelada') {
    return (
      <div className="tarjeta orden-cancelada" role="status">
        <strong>Orden cancelada{orden.cancelada_en && ` el ${fechaHora(orden.cancelada_en)}`}</strong>
        <span>Se conservan sus datos y lo que ya se había cargado, pero no admite cambios.</span>
        {liberadas && <span>{liberadas}</span>}
      </div>
    )
  }

  if (orden.estado !== 'abierta' || usuario?.rol !== 'administrador') return null

  if (!confirmando) {
    return (
      <div className="acciones">
        <button
          type="button"
          className="secundario peligro"
          onClick={() => {
            mutation.reset()
            setConfirmando(true)
          }}
        >
          Cancelar orden
        </button>
      </div>
    )
  }

  const errores = fieldErrors(mutation.error).base

  return (
    <div className="tarjeta formulario cancelar-orden" role="group" aria-label="Cancelar la orden">
      <p>
        ¿Cancelar esta orden? Usalo cuando el cliente decide no continuar. La orden queda identificada como cancelada y
        ya no se le pueden cargar tareas ni repuestos.
      </p>
      <p className="advertencia">
        Se conservan sus datos, las tareas terminadas y los repuestos cargados. Las tareas en curso se liberan. No se
        puede deshacer.
      </p>
      {mutation.isError && (
        <p className="error" role="alert">
          {errores?.join('. ') ?? errorMessage(mutation.error, 'No se pudo cancelar la orden.')}
        </p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={() => setConfirmando(false)}>
          No cancelar
        </button>
        <button type="button" className="peligro" disabled={mutation.isPending} onClick={() => mutation.mutate()}>
          {mutation.isPending ? 'Cancelando…' : 'Sí, cancelar la orden'}
        </button>
      </div>
    </div>
  )
}
