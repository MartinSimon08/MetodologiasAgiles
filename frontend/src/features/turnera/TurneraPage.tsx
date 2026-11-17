import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { errorMessage } from '../../lib/api'
import { fechaCorta as fechaTurno } from '../casos/api'
import { TurnoForm } from '../casos/TurnoForm'
import { ESTADO_TURNO_LABELS, obtenerTurnera, type DiaTurnera, type PeriodoTurnera } from './api'
import { CalendarioTurnera } from './CalendarioTurnera'
import { aIso, fechaCorta, mismoMes, nombreDia, nombreMes, primerDiaDelMes, sumarDias } from './fechas'

interface DiaTurneraProps {
  dia: DiaTurnera
  cupo: number
  esHoy: boolean
  reprogramandoId: number | null
  onReprogramar: (casoId: number | null) => void
  onReprogramado: (aviso: string) => void
}

function DiaTurneraTarjeta({ dia, cupo, esHoy, reprogramandoId, onReprogramar, onReprogramado }: DiaTurneraProps) {
  const clases = ['dia-turnera', esHoy && 'dia-turnera-hoy', dia.supera_cupo && 'dia-turnera-excedido']
    .filter(Boolean)
    .join(' ')

  return (
    <li className={clases} aria-current={esHoy ? 'date' : undefined}>
      <header className="dia-turnera-encabezado">
        <h2>
          {nombreDia(dia.fecha)}
          {esHoy && <span className="insignia">Hoy</span>}
        </h2>
        <span className="dia-turnera-cupo">
          <strong>
            {dia.ingresos} / {cupo}
          </strong>{' '}
          ingresos
          {dia.supera_cupo && <span className="insignia insignia-supera_cupo">Supera el cupo</span>}
        </span>
      </header>

      {dia.turnos.length === 0 ? (
        <p className="estado">Sin turnos.</p>
      ) : (
        <ul className="lista">
          {dia.turnos.map((turno) => (
            <li key={turno.caso_id} className="tarjeta item">
              <div className="item-datos">
                <strong>
                  Siniestro {turno.numero_siniestro} · {turno.aseguradora.nombre}
                </strong>
                <span>
                  {turno.asegurado.nombre} · <span className="patente">{turno.vehiculo.patente}</span>
                  {[turno.vehiculo.marca, turno.vehiculo.modelo].filter(Boolean).length > 0 &&
                    ` ${[turno.vehiculo.marca, turno.vehiculo.modelo].filter(Boolean).join(' ')}`}
                </span>
                {turno.orden_id !== null && <Link to={`/ordenes/${turno.orden_id}`}>Ver orden #{turno.orden_id}</Link>}
              </div>
              <div className="item-insignias">
                <span className={`insignia insignia-${turno.estado}`}>{ESTADO_TURNO_LABELS[turno.estado]}</span>
                {turno.estado === 'turno_asignado' && reprogramandoId !== turno.caso_id && (
                  <button type="button" className="secundario" onClick={() => onReprogramar(turno.caso_id)}>
                    Reprogramar
                  </button>
                )}
              </div>
              {reprogramandoId === turno.caso_id && (
                <TurnoForm
                  casoId={turno.caso_id}
                  numeroSiniestro={turno.numero_siniestro}
                  fechaActual={dia.fecha}
                  onCancelar={() => onReprogramar(null)}
                  onListo={(caso) => {
                    onReprogramar(null)
                    onReprogramado(`Se reprogramó el turno del caso ${caso.numero_siniestro} para el ${fechaTurno(caso.fecha_turno!)}.`)
                  }}
                />
              )}
            </li>
          ))}
        </ul>
      )}
    </li>
  )
}

export function TurneraPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const fecha = searchParams.get('fecha') ?? undefined
  const periodo: PeriodoTurnera = searchParams.get('vista') === 'mes' ? 'mes' : 'semana'
  const hoy = aIso(new Date())
  const referencia = fecha ?? hoy
  const [reprogramandoId, setReprogramandoId] = useState<number | null>(null)
  const [aviso, setAviso] = useState<string | null>(null)

  const turnera = useQuery({
    queryKey: ['turnera', periodo, fecha ?? 'actual'],
    queryFn: () => obtenerTurnera(fecha, periodo),
    placeholderData: keepPreviousData,
  })

  function parametros(nuevoPeriodo: PeriodoTurnera, nuevaFecha: string | null) {
    const params = new URLSearchParams()
    if (nuevoPeriodo === 'mes') params.set('vista', 'mes')
    if (nuevaFecha) params.set('fecha', nuevaFecha)
    return params
  }

  function irA(nuevaFecha: string | null) {
    setSearchParams(parametros(periodo, nuevaFecha), { replace: true })
  }

  const datos = turnera.data?.periodo === periodo ? turnera.data : undefined
  const semana = periodo === 'semana' ? datos : undefined
  const mes = periodo === 'mes' ? datos : undefined
  const esSemanaActual = semana ? semana.desde <= hoy && hoy <= semana.hasta : true

  return (
    <section className="turnera">
      <EncabezadoPagina
        titulo="Turnera"
        bajada="Casos con turno agrupados por día, contra el cupo diario de ingresos."
      />

      <nav className="subnav" aria-label="Vista de la turnera">
        <Link
          to={`?${parametros('semana', fecha ?? null)}`}
          className={periodo === 'semana' ? 'active' : undefined}
          aria-current={periodo === 'semana' ? 'page' : undefined}
        >
          Semana
        </Link>
        <Link
          to={`?${parametros('mes', fecha ?? null)}`}
          className={periodo === 'mes' ? 'active' : undefined}
          aria-current={periodo === 'mes' ? 'page' : undefined}
        >
          Calendario
        </Link>
      </nav>

      {mes && (
        <nav className="turnera-semana" aria-label="Mes">
          <strong>
            {nombreMes(referencia)} · Cupo diario {mes.cupo_diario}
          </strong>
          <div className="acciones">
            <button type="button" className="secundario" onClick={() => irA(primerDiaDelMes(referencia, -1))}>
              Mes anterior
            </button>
            {!mismoMes(referencia, hoy) && (
              <button type="button" className="secundario" onClick={() => irA(null)}>
                Este mes
              </button>
            )}
            <button type="button" className="secundario" onClick={() => irA(primerDiaDelMes(referencia, 1))}>
              Mes siguiente
            </button>
          </div>
        </nav>
      )}

      {semana && (
        <nav className="turnera-semana" aria-label="Semana">
          <strong>
            {fechaCorta(semana.desde)} al {fechaCorta(semana.hasta)} · Cupo diario {semana.cupo_diario}
          </strong>
          <div className="acciones">
            <button type="button" className="secundario" onClick={() => irA(sumarDias(semana.desde, -7))}>
              Semana anterior
            </button>
            {!esSemanaActual && (
              <button type="button" className="secundario" onClick={() => irA(null)}>
                Esta semana
              </button>
            )}
            <button type="button" className="secundario" onClick={() => irA(sumarDias(semana.desde, 7))}>
              Semana siguiente
            </button>
          </div>
        </nav>
      )}

      {aviso && (
        <p className="aviso" role="status">
          {aviso}
        </p>
      )}

      {!datos && !turnera.isError && <Cargando />}
      {turnera.isError && (
        <p className="error" role="alert">
          {errorMessage(turnera.error, 'No se pudo cargar la turnera.')}
        </p>
      )}

      {mes && (
        <CalendarioTurnera
          dias={mes.dias}
          cupo={mes.cupo_diario}
          mes={referencia}
          hoy={hoy}
          ocupado={turnera.isPlaceholderData}
        />
      )}

      {semana && (
        <ol className="dias-turnera" aria-busy={turnera.isPlaceholderData}>
          {semana.dias.map((dia) => (
            <DiaTurneraTarjeta
              key={dia.fecha}
              dia={dia}
              cupo={semana.cupo_diario}
              esHoy={dia.fecha === hoy}
              reprogramandoId={reprogramandoId}
              onReprogramar={(casoId) => {
                setAviso(null)
                setReprogramandoId(casoId)
              }}
              onReprogramado={setAviso}
            />
          ))}
        </ol>
      )}
    </section>
  )
}
