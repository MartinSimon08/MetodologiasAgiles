interface Props {
  titulo: string
  descripcion?: string
  busqueda?: boolean
}

export function EstadoVacio({ titulo, descripcion, busqueda = false }: Props) {
  return (
    <div className="estado-vacio" role="status">
      <svg
        width="40"
        height="40"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinecap="round"
        strokeLinejoin="round"
        aria-hidden="true"
      >
        {busqueda ? (
          <>
            <circle cx="11" cy="11" r="6" />
            <path d="m20 20-4.5-4.5" />
          </>
        ) : (
          <>
            <path d="M3 13h5l1.5 3h5L16 13h5" />
            <path d="M5.5 6h13L21 13v5a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-5z" />
          </>
        )}
      </svg>
      <strong>{titulo}</strong>
      {descripcion && <p>{descripcion}</p>}
    </div>
  )
}
