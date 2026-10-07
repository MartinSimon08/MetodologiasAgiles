export interface Sugerencia {
  id: number
  titulo: string
  detalle?: string
}

interface Props {
  id: string
  cargando: boolean
  error: string | null
  items: Sugerencia[]
  activo: number
  vacio: string
  aviso?: string
  onElegir: (id: number) => void
  onResaltar: (indice: number) => void
}

export function ListaSugerencias({
  id,
  cargando,
  error,
  items,
  activo,
  vacio,
  aviso,
  onElegir,
  onResaltar,
}: Props) {
  if (error) {
    return (
      <p className="error" role="alert">
        {error}
      </p>
    )
  }

  if (cargando) {
    return <p className="sugerencias-estado">Buscando…</p>
  }

  if (items.length === 0) {
    return <p className="sugerencias-estado">{vacio}</p>
  }

  const indice = Math.min(activo, items.length - 1)

  return (
    <div className="sugerencias-bloque">
      <ul id={id} className="sugerencias" role="listbox">
        {items.map((item, posicion) => (
          <li key={item.id} role="presentation">
            <button
              type="button"
              id={`${id}-opcion-${posicion}`}
              role="option"
              aria-selected={posicion === indice}
              onMouseEnter={() => onResaltar(posicion)}
              onMouseDown={(event) => event.preventDefault()}
              onClick={() => onElegir(item.id)}
            >
              <span>{item.titulo}</span>
              {item.detalle ? <small>{item.detalle}</small> : null}
            </button>
          </li>
        ))}
      </ul>
      {aviso ? <small className="sugerencias-aviso">{aviso}</small> : null}
    </div>
  )
}
