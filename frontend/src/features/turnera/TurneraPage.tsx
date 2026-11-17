import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { Cargando } from '../../components/Cargando'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { errorMessage } from '../../lib/api'
import { fechaCorta as fechaTurno } from '../casos/api'
import { TurnoForm } from '../casos/TurnoForm'
import { ESTADO_TURNO_LABELS, obtenerTurnera, type DiaTurnera } from './api'

function desdeIso(iso: string) {
  const [anio, mes, dia] = iso.split('-').map(Number)
  return new Date(anio, mes - 1, dia)
}

function aIso(fecha: Date) {
  const mes = String(fecha.getMonth() + 1).padStart(2, '0')
  const dia = String(fecha.getDate()).padStart(2, '0')
  return `${fecha.getFullYear()}-${mes}-${dia}`
}

function sumarDias(iso: string, dias: number) {
  const fecha = desdeIso(iso)
  fecha.setDate(fecha.getDate() + dias)
  return aIso(fecha)
}

function nombreDia(iso: string) {
  const texto = desdeIso(iso).toLocaleDateString('es-AR', { weekday: 'long', day: 'numeric', month: 'long' })
  return texto.charAt(0).toUpperCase() + texto.slice(1)
}

function fechaCorta(iso: string) {
  return desdeIso(iso).toLocaleDateString('es-AR', { day: '2-digit', month: '2-digit' })
}

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
  const hoy = aIso(new Date())
  const [reprogramandoId, setReprogramandoId] = useState<number | null>(null)
  const [aviso, setAviso] = useState<string | null>(null)

  const turnera = useQuery({
    queryKey: ['turnera', fecha ?? 'actual'],
    queryFn: () => obtenerTurnera(fecha),
    placeholderData: keepPreviousData,
  })

  function irA(nuevaFecha: string | null) {
    setSearchParams(nuevaFecha ? { fecha: nuevaFecha } : {}, { replace: true })
  }

  const semana = turnera.data
  const esSemanaActual = semana ? semana.desde <= hoy && hoy <= semana.hasta : true

  return (
    <section className="turnera">
      <EncabezadoPagina
        titulo="Turnera"
        bajada="Casos con turno de la semana, agrupados por día, contra el cupo diario de ingresos."
      />

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

      {turnera.isPending && <Cargando />}
      {turnera.isError && (
        <p className="error" role="alert">
          {errorMessage(turnera.error, 'No se pudo cargar la turnera.')}
        </p>
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
