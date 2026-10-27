import { useEffect, useRef, useState, type MouseEvent } from 'react'
import { flushSync } from 'react-dom'

type Tema = 'light' | 'dark'

const CLAVE_HUEVO = 'huevo-servidor'
const CAMBIOS_PARA_HUEVO = 6
const VENTANA_MS = 10000

function huevoYaMostrado() {
  try {
    return sessionStorage.getItem(CLAVE_HUEVO) === '1'
  } catch {
    return false
  }
}

function temaActual(): Tema {
  return document.documentElement.dataset.tema === 'dark' ? 'dark' : 'light'
}

export function SelectorTema({ className = '' }: { className?: string }) {
  const [tema, setTema] = useState<Tema>(temaActual)
  const oscuro = tema === 'dark'
  const [huevo, setHuevo] = useState(false)
  const cambios = useRef<number[]>([])

  useEffect(() => {
    if (!huevo) return
    const id = setTimeout(() => setHuevo(false), 4500)
    return () => clearTimeout(id)
  }, [huevo])

  function contarCambio() {
    const ahora = Date.now()
    cambios.current = [...cambios.current, ahora].filter((t) => ahora - t < VENTANA_MS)
    if (cambios.current.length >= CAMBIOS_PARA_HUEVO && !huevoYaMostrado()) {
      try {
        sessionStorage.setItem(CLAVE_HUEVO, '1')
      } catch {
        /* almacenamiento no disponible */
      }
      cambios.current = []
      setHuevo(true)
    }
  }

  function alternar(event: MouseEvent<HTMLButtonElement>) {
    contarCambio()
    const siguiente: Tema = oscuro ? 'light' : 'dark'
    const aplicar = () => {
      flushSync(() => setTema(siguiente))
      document.documentElement.dataset.tema = siguiente
      try {
        localStorage.setItem('tema', siguiente)
      } catch {
        /* almacenamiento no disponible */
      }
    }
    const rect = event.currentTarget.getBoundingClientRect()
    const estilo = document.documentElement.style
    estilo.setProperty('--tx', `${rect.left + rect.width / 2}px`)
    estilo.setProperty('--ty', `${rect.top + rect.height / 2}px`)
    if (document.startViewTransition) document.startViewTransition(aplicar)
    else aplicar()
  }

  return (
    <button
      type="button"
      role="switch"
      aria-checked={oscuro}
      aria-label="Modo oscuro"
      title={oscuro ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'}
      className={`selector-tema ${className}`.trim()}
      onClick={alternar}
    >
      <span className="astro" />
      <span className="estrella" />
      <span className="estrella" />
      <span className="estrella" />
      {huevo && (
        <span className="huevo-servidor" role="status">
          <span className="huevo-icono" aria-hidden="true">🖥️</span>
          ¡Pará, pará, pará! Me vas a tirar el servidor
        </span>
      )}
    </button>
  )
}
