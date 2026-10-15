import type { ReactNode } from 'react'

interface Props {
  titulo: string
  bajada?: string
  children?: ReactNode
}

export function EncabezadoPagina({ titulo, bajada, children }: Props) {
  return (
    <header className="encabezado">
      <div>
        <h1>{titulo}</h1>
        {bajada && <p className="bajada">{bajada}</p>}
      </div>
      {children}
    </header>
  )
}
