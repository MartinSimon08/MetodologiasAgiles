import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'

export function EnlaceEntidad({ a, children }: { a: string; children: ReactNode }) {
  return (
    <Link to={a} className="enlace-fila">
      {children}
    </Link>
  )
}
