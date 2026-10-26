import { useEffect, type ReactNode } from 'react'
import { createPortal } from 'react-dom'

interface Props {
  onCerrar: () => void
  children: ReactNode
}

export function Dialogo({ onCerrar, children }: Props) {
  useEffect(() => {
    function alTecla(event: KeyboardEvent) {
      if (event.key === 'Escape') onCerrar()
    }
    document.addEventListener('keydown', alTecla)
    return () => document.removeEventListener('keydown', alTecla)
  }, [onCerrar])

  return createPortal(
    <div className="dialogo-fondo" role="dialog" aria-modal="true" onSubmit={(event) => event.stopPropagation()}>
      <div className="dialogo">{children}</div>
    </div>,
    document.body,
  )
}
