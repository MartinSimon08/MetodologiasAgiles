import type { ReactNode } from 'react'

interface Props {
  etiqueta: string
  ocupada?: boolean
  children: ReactNode
}

export function Tabla({ etiqueta, ocupada = false, children }: Props) {
  return (
    <div className="tabla-contenedor">
      <table className="tabla" aria-label={etiqueta} aria-busy={ocupada}>
        {children}
      </table>
    </div>
  )
}
