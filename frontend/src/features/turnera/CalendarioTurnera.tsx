import { Link } from 'react-router-dom'
import { ESTADO_TURNO_LABELS, type DiaTurnera } from './api'
import { desdeIso, mismoMes, nombreDia } from './fechas'

const DIAS_SEMANA = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']
const TURNOS_VISIBLES = 3

interface Props {
  dias: DiaTurnera[]
  cupo: number
  mes: string
  hoy: string
  ocupado: boolean
}

export function CalendarioTurnera({ dias, cupo, mes, hoy, ocupado }: Props) {
  return (
    <div className="calendario-turnera" aria-busy={ocupado}>
      <div className="calendario-turnera-semana" aria-hidden="true">
        {DIAS_SEMANA.map((dia) => (
          <span key={dia}>{dia}</span>
        ))}
      </div>
      <ol className="calendario-turnera-dias">
        {dias.map((dia) => {
          const esHoy = dia.fecha === hoy
          const clases = [
            'calendario-turnera-dia',
            !mismoMes(dia.fecha, mes) && 'fuera-de-mes',
            esHoy && 'hoy',
            dia.supera_cupo && 'excedido',
          ]
            .filter(Boolean)
            .join(' ')
          const ocultos = dia.turnos.length - TURNOS_VISIBLES
          const etiqueta = `${nombreDia(dia.fecha)}: ${dia.ingresos} de ${cupo} ingresos${
            dia.supera_cupo ? ', supera el cupo' : ''
          }. Ver la semana.`

          return (
            <li key={dia.fecha} className={clases} aria-current={esHoy ? 'date' : undefined}>
              <Link to={`/turnera?fecha=${dia.fecha}`} aria-label={etiqueta}>
                <span className="calendario-turnera-encabezado">
                  <span className="calendario-turnera-numero">{desdeIso(dia.fecha).getDate()}</span>
                  {dia.ingresos > 0 && (
                    <span className="calendario-turnera-cupo">
                      {dia.ingresos}/{cupo}
                    </span>
                  )}
                </span>
                {dia.turnos.length > 0 && (
                  <span className="calendario-turnera-turnos">
                    {dia.turnos.slice(0, TURNOS_VISIBLES).map((turno) => (
                      <span
                        key={turno.caso_id}
                        className={`calendario-turno calendario-turno-${turno.estado}`}
                        title={`${turno.vehiculo.patente} · ${turno.asegurado.nombre} · ${ESTADO_TURNO_LABELS[turno.estado]}`}
                      >
                        {turno.vehiculo.patente}
                      </span>
                    ))}
                    {ocultos > 0 && <span className="calendario-turno-mas">+{ocultos} más</span>}
                  </span>
                )}
              </Link>
            </li>
          )
        })}
      </ol>
    </div>
  )
}
