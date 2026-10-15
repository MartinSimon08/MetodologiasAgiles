interface Props {
  etiqueta: string
  valor: string
  onCambiar: (valor: string) => void
  placeholder?: string
  autoFocus?: boolean
}

export function Buscador({ etiqueta, valor, onCambiar, placeholder, autoFocus }: Props) {
  return (
    <label className="buscador">
      <span>{etiqueta}</span>
      <span className="buscador-campo">
        <svg
          width="18"
          height="18"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          aria-hidden="true"
        >
          <circle cx="11" cy="11" r="7" />
          <path d="m20 20-3.5-3.5" />
        </svg>
        <input
          type="search"
          autoFocus={autoFocus}
          autoComplete="off"
          enterKeyHint="search"
          placeholder={placeholder}
          value={valor}
          onChange={(e) => onCambiar(e.target.value)}
        />
      </span>
    </label>
  )
}
