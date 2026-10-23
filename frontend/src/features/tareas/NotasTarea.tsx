import { fechaHora } from '../../lib/formato'
import type { Nota } from './types'

interface Props {
  notas: Nota[]
}

export function NotasTarea({ notas }: Props) {
  if (notas.length === 0) return null

  return (
    <ul className="notas">
      {notas.map((nota) => (
        <li key={nota.id}>
          <small>
            {nota.registrado_por.nombre} · {fechaHora(nota.created_at)}
          </small>
          {nota.contenido}
        </li>
      ))}
    </ul>
  )
}
