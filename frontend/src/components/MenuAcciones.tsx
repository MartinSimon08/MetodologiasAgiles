import { useEffect, useId, useRef, useState, type CSSProperties, type KeyboardEvent } from 'react'

export interface Accion {
  etiqueta: string
  onSeleccionar: () => void
  peligro?: boolean
  deshabilitada?: boolean
}

interface Props {
  etiqueta: string
  acciones: Accion[]
}

export function MenuAcciones({ etiqueta, acciones }: Props) {
  const [posicion, setPosicion] = useState<CSSProperties | null>(null)
  const abierto = posicion !== null
  const contenedor = useRef<HTMLDivElement>(null)
  const disparador = useRef<HTMLButtonElement>(null)
  const menuId = useId()

  useEffect(() => {
    if (!abierto) return
    function alClickAfuera(event: PointerEvent) {
      if (!contenedor.current?.contains(event.target as Node)) setPosicion(null)
    }
    function alMover() {
      setPosicion(null)
    }
    document.addEventListener('pointerdown', alClickAfuera)
    window.addEventListener('scroll', alMover, true)
    window.addEventListener('resize', alMover)
    contenedor.current?.querySelector<HTMLButtonElement>('[role="menuitem"]:not(:disabled)')?.focus()
    return () => {
      document.removeEventListener('pointerdown', alClickAfuera)
      window.removeEventListener('scroll', alMover, true)
      window.removeEventListener('resize', alMover)
    }
  }, [abierto])

  if (acciones.length === 0) return null

  function cerrar() {
    setPosicion(null)
    disparador.current?.focus()
  }

  function alternar() {
    if (abierto || !disparador.current) {
      setPosicion(null)
      return
    }
    const caja = disparador.current.getBoundingClientRect()
    const abajo = window.innerHeight - caja.bottom > 48 * acciones.length + 16
    setPosicion({
      right: window.innerWidth - caja.right,
      ...(abajo ? { top: caja.bottom + 4 } : { bottom: window.innerHeight - caja.top + 4 }),
    })
  }

  function alTecla(event: KeyboardEvent<HTMLDivElement>) {
    if (event.key === 'Escape') {
      event.stopPropagation()
      cerrar()
      return
    }
    if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return
    event.preventDefault()
    const items = Array.from(
      contenedor.current?.querySelectorAll<HTMLButtonElement>('[role="menuitem"]:not(:disabled)') ?? [],
    )
    const actual = items.indexOf(document.activeElement as HTMLButtonElement)
    const paso = event.key === 'ArrowDown' ? 1 : -1
    items[(actual + paso + items.length) % items.length]?.focus()
  }

  return (
    <div className="menu-acciones" ref={contenedor} onKeyDown={abierto ? alTecla : undefined}>
      <button
        ref={disparador}
        type="button"
        className="menu-acciones-disparador"
        aria-label={etiqueta}
        aria-haspopup="menu"
        aria-expanded={abierto}
        aria-controls={abierto ? menuId : undefined}
        onClick={alternar}
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
          <circle cx="5" cy="12" r="1.6" />
          <circle cx="12" cy="12" r="1.6" />
          <circle cx="19" cy="12" r="1.6" />
        </svg>
      </button>
      {abierto && (
        <div className="menu-acciones-lista" role="menu" id={menuId} aria-label={etiqueta} style={posicion}>
          {acciones.map((accion) => (
            <button
              key={accion.etiqueta}
              type="button"
              role="menuitem"
              className={accion.peligro ? 'peligro' : undefined}
              disabled={accion.deshabilitada}
              onClick={() => {
                cerrar()
                accion.onSeleccionar()
              }}
            >
              {accion.etiqueta}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
