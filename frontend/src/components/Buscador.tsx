import type { KeyboardEvent, Ref } from 'react'

interface Props {
  etiqueta: string
  valor: string
  onCambiar: (valor: string) => void
  placeholder?: string
  autoFocus?: boolean
  inputRef?: Ref<HTMLInputElement>
  onKeyDown?: (event: KeyboardEvent<HTMLInputElement>) => void
}

export function Buscador({ etiqueta, valor, onCambiar, placeholder, autoFocus, inputRef, onKeyDown }: Props) {
  return (
    <label className="buscador">
      <span>{etiqueta}</span>
      <input
        ref={inputRef}
        type="search"
        autoFocus={autoFocus}
        autoComplete="off"
        enterKeyHint="search"
        placeholder={placeholder}
        value={valor}
        onChange={(e) => onCambiar(e.target.value)}
        onKeyDown={onKeyDown}
      />
    </label>
  )
}
