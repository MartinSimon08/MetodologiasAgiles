import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { errorMessage } from '../../lib/api'
import { avisarCierre, obtenerAvisosCierre, type DestinoAviso } from './api'

export function AvisosCierre({ ordenId }: { ordenId: number }) {
  const queryClient = useQueryClient()
  const destinos = useQuery({ queryKey: ['avisos-cierre', ordenId], queryFn: () => obtenerAvisosCierre(ordenId) })
  const avisar = useMutation({
    mutationFn: ({ destino, medio }: { destino: DestinoAviso['destino']; medio: 'email' | 'telegram' }) =>
      avisarCierre(ordenId, destino, medio),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['caso'] }),
  })

  if (!destinos.data) return null

  return (
    <section className="bloque-cierre">
      <h3>Avisos del cierre</h3>
      <ul className="lineas-cierre">
        {destinos.data.map((destino) => (
          <li key={destino.destino}>
            <span>
              {destino.etiqueta}
              <small>
                {destino.nombre} · {destino.email ?? 'Sin email'} ·{' '}
                {destino.telegram_vinculada ? 'Telegram vinculado' : 'Telegram sin vincular'}
              </small>
            </span>
            {destino.destino === 'asegurado' ? (
              <button
                type="button"
                className="secundario"
                onClick={() => avisar.mutate({ destino: destino.destino, medio: 'email' })}
              >
                Enviar
              </button>
            ) : (
              <span className="acciones">
                <button
                  type="button"
                  className="secundario"
                  disabled={!destino.email || avisar.isPending}
                  onClick={() => avisar.mutate({ destino: destino.destino, medio: 'email' })}
                >
                  Email
                </button>
                <button
                  type="button"
                  className="secundario"
                  disabled={!destino.telegram_vinculada || avisar.isPending}
                  onClick={() => avisar.mutate({ destino: destino.destino, medio: 'telegram' })}
                >
                  Telegram
                </button>
              </span>
            )}
          </li>
        ))}
      </ul>
      {avisar.isSuccess && (
        <p className="estado" role="status">
          Aviso enviado.
        </p>
      )}
      {avisar.isError && (
        <p className="error" role="alert">
          {errorMessage(avisar.error, 'No se pudo enviar el aviso.')}
        </p>
      )}
    </section>
  )
}
