import type { ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'

const INTERACTIVOS = 'a, button, input, select, textarea, [role="menu"], [role="dialog"]'

interface Props {
  a: string
  className?: string
  children: ReactNode
}

export function FilaEnlace({ a, className, children }: Props) {
  const navigate = useNavigate()

  return (
    <tr
      className={['fila-clicable', className].filter(Boolean).join(' ')}
      onClick={(evento) => {
        if ((evento.target as HTMLElement).closest(INTERACTIVOS)) return
        navigate(a)
      }}
    >
      {children}
    </tr>
  )
}
