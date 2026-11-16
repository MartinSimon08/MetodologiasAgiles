import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { errorMessage, fieldErrors } from '../../lib/api'
import { fechaHora, importe } from '../../lib/formato'
import { corregirOrden, listarCorrecciones } from './api'
import { CAMPO_CORRECCION_LABELS, MOTIVO_LARGO_MAXIMO, type ResumenCierre } from './types'

interface Props {
  ordenId: number
  resumen: ResumenCierre
}

function monto(valor: string | null) {
  return valor == null ? 'sin valor' : `$ ${importe(valor)}`
}

function Historial({ ordenId }: { ordenId: number }) {
  const correcciones = useQuery({
    queryKey: ['correcciones', ordenId],
    queryFn: () => listarCorrecciones(ordenId),
  })

  if (!correcciones.data || correcciones.data.length === 0) return null

  return (
    <section className="bloque-cierre">
      <h3>Correcciones registradas</h3>
      <ul className="lineas-cierre">
        {correcciones.data.map((correccion) => (
          <li key={correccion.id}>
            <span>
              {CAMPO_CORRECCION_LABELS[correccion.campo]}: {monto(correccion.valor_anterior)} →{' '}
              {monto(correccion.valor_nuevo)}
              <small>
                {correccion.usuario.nombre} · {fechaHora(correccion.created_at)} · {correccion.motivo}
                {correccion.revision_confirmada ? ' · Franquicia y saldo revisados' : ''}
              </small>
            </span>
          </li>
        ))}
      </ul>
    </section>
  )
}

export function CorregirOrden({ ordenId, resumen }: Props) {
  const queryClient = useQueryClient()
  const [corrigiendo, setCorrigiendo] = useState(false)
  const [totalCerrado, setTotalCerrado] = useState('')
  const [franquicia, setFranquicia] = useState('')
  const [motivo, setMotivo] = useState('')
  const [revisado, setRevisado] = useState(false)

  const mutation = useMutation({
    mutationFn: () =>
      corregirOrden(ordenId, {
        motivo,
        totalCerrado: totalCerrado.trim() === '' ? undefined : totalCerrado.trim(),
        franquicia: franquicia.trim() === '' ? undefined : franquicia.trim(),
        confirmarRevision: revisado,
      }),
    onSuccess: () => {
      setCorrigiendo(false)
      queryClient.invalidateQueries({ queryKey: ['orden', ordenId] })
      queryClient.invalidateQueries({ queryKey: ['ordenes'] })
      queryClient.invalidateQueries({ queryKey: ['resumen-cierre', ordenId] })
      queryClient.invalidateQueries({ queryKey: ['correcciones', ordenId] })
      queryClient.invalidateQueries({ queryKey: ['adelantos', ordenId] })
    },
  })

  const errores = fieldErrors(mutation.error)
  const pideRevision =
    Number(resumen.franquicia) > 0 || (errores.base ?? []).some((mensaje) => mensaje.includes('Confirmá que los revisaste'))
  const hayCambios = totalCerrado.trim() !== '' || franquicia.trim() !== ''
  const mensajesError = [
    ...(errores.base ?? []),
    ...(errores.motivo_correccion ?? []),
    ...(errores.total_cerrado ?? []),
    ...(errores.franquicia ?? []),
  ]

  if (!corrigiendo) {
    return (
      <>
        <Historial ordenId={ordenId} />
        <div className="acciones">
          <button
            type="button"
            className="secundario"
            onClick={() => {
              mutation.reset()
              setTotalCerrado('')
              setFranquicia('')
              setMotivo('')
              setRevisado(false)
              setCorrigiendo(true)
            }}
          >
            Corregir orden
          </button>
        </div>
      </>
    )
  }

  return (
    <div className="tarjeta formulario" role="group" aria-label="Corregir la orden cerrada">
      <h2>Corregir la orden cerrada</h2>
      <p className="estado">
        Total actual: $ {importe(resumen.total)}
        {Number(resumen.franquicia) > 0 && ` · Franquicia: $ ${importe(resumen.franquicia ?? 0)}`}. Completá solo lo que
        querés cambiar.
      </p>

      <label>
        <span>Nuevo total ($)</span>
        <input
          type="number"
          inputMode="decimal"
          min="0"
          step="0.01"
          value={totalCerrado}
          onChange={(event) => setTotalCerrado(event.target.value)}
          disabled={mutation.isPending}
        />
      </label>

      <label>
        <span>Nueva franquicia del asegurado ($)</span>
        <input
          type="number"
          inputMode="decimal"
          min="0"
          step="0.01"
          value={franquicia}
          onChange={(event) => setFranquicia(event.target.value)}
          disabled={mutation.isPending}
        />
        <small>Para quitar la franquicia, poné 0.</small>
      </label>

      <label>
        <span>Motivo de la corrección</span>
        <textarea
          value={motivo}
          maxLength={MOTIVO_LARGO_MAXIMO}
          rows={3}
          onChange={(event) => setMotivo(event.target.value)}
          disabled={mutation.isPending}
        />
      </label>

      {pideRevision && (
        <label className="descartar-pendientes">
          <span>
            <input type="checkbox" checked={revisado} onChange={(event) => setRevisado(event.target.checked)} />
            Revisé la franquicia y el saldo a facturar
          </span>
          <small>
            Si ya se cobró la franquicia o se facturó el saldo a la aseguradora, ese registro hay que revisarlo a mano.
          </small>
        </label>
      )}

      <p className="advertencia">La corrección queda registrada con el valor anterior, el nuevo, tu usuario y la fecha.</p>

      {mutation.isError && (
        <p className="error" role="alert">
          {mensajesError.length > 0 ? mensajesError.join('. ') : errorMessage(mutation.error, 'No se pudo corregir la orden.')}
        </p>
      )}

      <div className="acciones">
        <button type="button" className="secundario" onClick={() => setCorrigiendo(false)}>
          Volver
        </button>
        <button
          type="button"
          disabled={!hayCambios || motivo.trim() === '' || (pideRevision && !revisado) || mutation.isPending}
          onClick={() => mutation.mutate()}
        >
          {mutation.isPending ? 'Guardando…' : 'Confirmar corrección'}
        </button>
      </div>
    </div>
  )
}
