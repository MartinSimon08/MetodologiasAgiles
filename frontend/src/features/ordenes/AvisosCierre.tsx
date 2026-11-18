import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { errorMessage } from '../../lib/api'
import { avisarCierre, obtenerAvisosCierre } from './api'

export function AvisosCierre({ ordenId }: { ordenId: number }) {
  const queryClient = useQueryClient()
  const destinos = useQuery({ queryKey: ['avisos-cierre', ordenId], queryFn: () => obtenerAvisosCierre(ordenId) })
  const avisar = useMutation({
    mutationFn: (destino: Parameters<typeof avisarCierre>[1]) => avisarCierre(ordenId, destino),
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
                {destino.nombre} · {destino.email ?? 'Sin email'}
              </small>
            </span>
            <button
              type="button"
              className="secundario"
              disabled={!destino.email && destino.destino !== 'asegurado'}
              onClick={() => avisar.mutate(destino.destino)}
            >
              Enviar
            </button>
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
