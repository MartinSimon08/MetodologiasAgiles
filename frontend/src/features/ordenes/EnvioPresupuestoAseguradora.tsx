import { useMutation, useQueryClient } from '@tanstack/react-query'
import { errorMessage } from '../../lib/api'
import { fechaHora } from '../../lib/formato'
import { enviarPresupuesto } from './api'
import type { Presupuesto } from './types'

// type Medio = 'email' | 'whatsapp'
type Medio = 'email' | 'telegram'

const MEDIO_LABELS: Record<Medio, string> = {
  email: 'Email',
  // whatsapp: 'WhatsApp',
  telegram: 'Telegram',
}

// function soloDigitos(valor: string) {
//   return valor.replace(/\D/g, '')
// }
//
// function componerMensaje(presupuesto: Presupuesto) {
//   const lineas = [`Presupuesto de la orden #${presupuesto.orden_id}`]
//   if (presupuesto.caso) lineas.push(`Siniestro ${presupuesto.caso.numero_siniestro}`)
//   lineas.push(`Total para la aseguradora: $ ${importe(presupuesto.total_aseguradora)}`)
//   return lineas.join('\n')
// }
//
// function componerEnlace(
//   medio: Medio,
//   aseguradora: NonNullable<Presupuesto['aseguradora']>,
//   mensaje: string,
//   ordenId: number,
// ): string | null {
//   if (medio === 'email') {
//     const asunto = `Presupuesto orden #${ordenId}`
//     return `mailto:${aseguradora.email}?subject=${encodeURIComponent(asunto)}&body=${encodeURIComponent(mensaje)}`
//   }
//   // return `https://wa.me/${soloDigitos(aseguradora.telefono ?? '')}?text=${encodeURIComponent(mensaje)}`
//   return null
// }

export function EnvioPresupuestoAseguradora({ ordenId, presupuesto }: { ordenId: number; presupuesto: Presupuesto }) {
  const queryClient = useQueryClient()
  const aseguradora = presupuesto.aseguradora
  const enviar = useMutation({
    mutationFn: (medio: Medio) => enviarPresupuesto(ordenId, medio),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['presupuesto', ordenId] }),
  })

  function enviarPor(medio: Medio) {
    if (!aseguradora) return
    enviar.mutate(medio)
  }

  return (
    <>
      <section className="bloque-cierre">
        <h3>Envío a la aseguradora</h3>
        {presupuesto.caso === null ? (
          <p className="estado">La orden todavía no está vinculada a un caso.</p>
        ) : (
          aseguradora && (
            <>
              <p className="estado">
                {aseguradora.nombre}
                {aseguradora.email ? ` · ${aseguradora.email}` : ' · Sin email'}
                {aseguradora.telefono ? ` · ${aseguradora.telefono}` : ' · Sin teléfono'}
              </p>
              {!aseguradora.telegram_vinculada && (
                <p className="estado">
                  Telegram sin vincular: la aseguradora tiene que escribirle al bot y compartir su contacto.
                </p>
              )}
              <span className="acciones">
                <button
                  type="button"
                  className="secundario"
                  disabled={!aseguradora.email || enviar.isPending}
                  onClick={() => enviarPor('email')}
                >
                  Enviar por email
                </button>
                {/* <button
                  type="button"
                  className="secundario"
                  disabled={!aseguradora.telefono || enviar.isPending}
                  onClick={() => enviarPor('whatsapp')}
                >
                  Enviar por WhatsApp
                </button> */}
                <button
                  type="button"
                  className="secundario"
                  disabled={!aseguradora.telegram_vinculada || enviar.isPending}
                  onClick={() => enviarPor('telegram')}
                >
                  Enviar por Telegram
                </button>
              </span>
            </>
          )
        )}
        {enviar.isError && (
          <p className="error" role="alert">
            {errorMessage(enviar.error, 'No se pudo registrar el envío.')}
          </p>
        )}
      </section>

      <section className="bloque-cierre">
        <h3>Envíos registrados</h3>
        {presupuesto.envios.length === 0 && <p className="estado">Todavía no se envió el presupuesto.</p>}
        <ul className="lineas-cierre">
          {presupuesto.envios.map((envio) => (
            <li key={envio.id}>
              <span>
                {MEDIO_LABELS[envio.medio]} a {envio.destinatario}
                <small>Por {envio.enviado_por.nombre}</small>
              </span>
              <span>{fechaHora(envio.enviado_en)}</span>
            </li>
          ))}
        </ul>
      </section>
    </>
  )
}
