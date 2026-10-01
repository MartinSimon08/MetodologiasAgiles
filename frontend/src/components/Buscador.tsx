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
      <input
        type="search"
        autoFocus={autoFocus}
        autoComplete="off"
        enterKeyHint="search"
        placeholder={placeholder}
        value={valor}
        onChange={(e) => onCambiar(e.target.value)}
      />
    </label>
  )
}
