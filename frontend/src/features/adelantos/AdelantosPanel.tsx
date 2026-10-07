import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { errorMessage } from '../../lib/api'
import { fechaHora, importe } from '../../lib/formato'
import { useAuth } from '../auth/AuthContext'
import { listarAdelantos, totalAdelantado } from './api'
import { NuevoAdelantoForm } from './NuevoAdelantoForm'

export function AdelantosPanel({ ordenId, ordenAbierta }: { ordenId: number; ordenAbierta: boolean }) {
  const { usuario } = useAuth()
  const esAdministrador = usuario?.rol === 'administrador'
  const [creando, setCreando] = useState(false)
  const [aviso, setAviso] = useState(false)

  const consulta = useQuery({
    queryKey: ['adelantos', ordenId],
    queryFn: () => listarAdelantos(ordenId),
    enabled: esAdministrador,
  })

  if (!esAdministrador) return null

  return (
    <section className="adelantos" aria-busy={consulta.isFetching}>
      <header className="encabezado">
        <div>
          <h2>Adelantos</h2>
          <p className="bajada">Señas a cuenta de esta orden. Descuentan el saldo y no la cierran.</p>
        </div>
        {ordenAbierta && !creando && (
          <button
            onClick={() => {
              setAviso(false)
              setCreando(true)
            }}
          >
            Registrar adelanto
          </button>
        )}
      </header>

      {aviso && (
        <p className="aviso" role="status">
          Adelanto registrado.
        </p>
      )}
      {creando && ordenAbierta && (
        <NuevoAdelantoForm
          ordenId={ordenId}
          saldo={consulta.data?.saldo}
          onCancelar={() => setCreando(false)}
          onGuardado={() => {
            setCreando(false)
            setAviso(true)
          }}
        />
      )}
      {!ordenAbierta && <p className="estado">Esta orden ya no admite adelantos.</p>}

      {consulta.isPending && <p className="estado">Cargando adelantos…</p>}
      {consulta.isError && (
        <p className="error" role="alert">
          {errorMessage(consulta.error, 'No se pudieron cargar los adelantos.')}
        </p>
      )}

      {consulta.data && (
        <>
          <p className="resumen-saldo">
            <strong>Saldo pendiente: $ {importe(consulta.data.saldo)}</strong>
            {consulta.data.adelantos.length > 0 && (
              <span>Adelantado: $ {importe(totalAdelantado(consulta.data.adelantos))}</span>
            )}
          </p>
          {consulta.data.adelantos.length === 0 && (
            <p className="estado">Todavía no hay adelantos en esta orden.</p>
          )}
          {consulta.data.adelantos.length > 0 && (
            <ul className="lista">
              {consulta.data.adelantos.map((adelanto) => (
                <li key={adelanto.id} className="tarjeta item-datos">
                  <strong>$ {importe(adelanto.importe)}</strong>
                  <span>{fechaHora(adelanto.registrado_en)}</span>
                </li>
              ))}
            </ul>
          )}
        </>
      )}
    </section>
  )
}
