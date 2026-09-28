interface Meta {
  pagina: number
  total: number
  total_paginas: number
}

interface Props {
  meta: Meta
  cargando?: boolean
  onCambiar: (pagina: number) => void
}

export function Paginacion({ meta, cargando = false, onCambiar }: Props) {
  if (meta.total_paginas <= 1) return null

  return (
    <nav className="paginacion" aria-label="Paginación">
      <button
        type="button"
        className="secundario"
        disabled={cargando || meta.pagina <= 1}
        onClick={() => onCambiar(meta.pagina - 1)}
      >
        Anterior
      </button>
      <span>
        Página {meta.pagina} de {meta.total_paginas}
        <small>{meta.total} en total</small>
      </span>
      <button
        type="button"
        className="secundario"
        disabled={cargando || meta.pagina >= meta.total_paginas}
        onClick={() => onCambiar(meta.pagina + 1)}
      >
        Siguiente
      </button>
    </nav>
  )
}
