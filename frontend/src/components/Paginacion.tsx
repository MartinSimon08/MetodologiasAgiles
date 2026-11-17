import { useId } from 'react'
import { OPCIONES_POR_PAGINA } from '../lib/paginacion'

interface Meta {
  pagina: number
  total: number
  total_paginas: number
  por_pagina?: number
}

interface Props {
  meta: Meta
  cargando?: boolean
  onCambiar: (pagina: number) => void
  porPagina?: number
  onCambiarPorPagina?: (porPagina: number) => void
}

export function Paginacion({ meta, cargando = false, onCambiar, porPagina, onCambiarPorPagina }: Props) {
  const selectorId = useId()
  const conSelector = porPagina !== undefined && onCambiarPorPagina !== undefined
  if (meta.total === 0) return null
  if (!conSelector && meta.total_paginas <= 1) return null

  const tamanio = porPagina ?? meta.por_pagina ?? meta.total
  const desde = meta.total === 0 ? 0 : (meta.pagina - 1) * tamanio + 1
  const hasta = Math.min(meta.pagina * tamanio, meta.total)

  return (
    <nav className="paginacion" aria-label="Paginación">
      {conSelector && (
        <label className="paginacion-cantidad" htmlFor={selectorId}>
          <span>Mostrar</span>
          <select
            id={selectorId}
            value={porPagina}
            disabled={cargando}
            onChange={(event) => onCambiarPorPagina(Number(event.target.value))}
          >
            {OPCIONES_POR_PAGINA.map((opcion) => (
              <option key={opcion} value={opcion}>
                {opcion}
              </option>
            ))}
          </select>
          <span>por página</span>
        </label>
      )}
      <span className="paginacion-rango">
        {desde}–{hasta} de {meta.total}
        {meta.total_paginas > 1 && (
          <small>
            Página {meta.pagina} de {meta.total_paginas}
          </small>
        )}
      </span>
      {meta.total_paginas > 1 && (
        <div className="paginacion-botones">
          <button
            type="button"
            className="secundario"
            disabled={cargando || meta.pagina <= 1}
            onClick={() => onCambiar(meta.pagina - 1)}
          >
            Anterior
          </button>
          <button
            type="button"
            className="secundario"
            disabled={cargando || meta.pagina >= meta.total_paginas}
            onClick={() => onCambiar(meta.pagina + 1)}
          >
            Siguiente
          </button>
        </div>
      )}
    </nav>
  )
}
