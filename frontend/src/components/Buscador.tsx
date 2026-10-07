import type { KeyboardEvent } from 'react'

interface Props {
  etiqueta: string
  valor: string
  onCambiar: (valor: string) => void
  placeholder?: string
  autoFocus?: boolean
  inputId?: string
  controles?: string
  expandido?: boolean
  activoId?: string
  onKeyDown?: (event: KeyboardEvent<HTMLInputElement>) => void
  onFocus?: () => void
}

export function Buscador({
  etiqueta,
  valor,
  onCambiar,
  placeholder,
  autoFocus,
  inputId,
  controles,
  expandido = false,
  activoId,
  onKeyDown,
  onFocus,
}: Props) {
  return (
    <label className="buscador">
      <span>{etiqueta}</span>
      <input
        id={inputId}
        type="search"
        role={controles ? 'combobox' : undefined}
        aria-expanded={controles ? expandido : undefined}
        aria-controls={controles}
        aria-autocomplete={controles ? 'list' : undefined}
        aria-activedescendant={expandido ? activoId : undefined}
        autoFocus={autoFocus}
        autoComplete="off"
        enterKeyHint="search"
        placeholder={placeholder}
        value={valor}
        onChange={(e) => onCambiar(e.target.value)}
        onKeyDown={onKeyDown}
        onFocus={onFocus}
      />
    </label>
  )
}
