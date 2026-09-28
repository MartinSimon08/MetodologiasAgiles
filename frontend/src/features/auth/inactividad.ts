import { useEffect } from 'react'

export const INACTIVIDAD_MAXIMA_MS = 30 * 60 * 1000

const ULTIMA_ACTIVIDAD_KEY = 'taller.ultimaActividad'
const EVENTOS = ['pointerdown', 'keydown', 'scroll', 'touchstart'] as const
const INTERVALO_REGISTRO_MS = 5 * 1000
const INTERVALO_CHEQUEO_MS = 15 * 1000

export const ultimaActividad = {
  get: () => Number(localStorage.getItem(ULTIMA_ACTIVIDAD_KEY)) || 0,
  registrar: () => localStorage.setItem(ULTIMA_ACTIVIDAD_KEY, String(Date.now())),
}

export function useCierrePorInactividad(activo: boolean, onInactivo: () => void) {
  useEffect(() => {
    if (!activo) return

    let ultimoRegistro = 0
    function registrar() {
      const ahora = Date.now()
      if (ahora - ultimoRegistro < INTERVALO_REGISTRO_MS) return
      ultimoRegistro = ahora
      ultimaActividad.registrar()
    }

    function chequear() {
      if (Date.now() - ultimaActividad.get() > INACTIVIDAD_MAXIMA_MS) onInactivo()
    }

    chequear()
    EVENTOS.forEach((evento) => window.addEventListener(evento, registrar, { passive: true }))
    document.addEventListener('visibilitychange', chequear)
    const intervalo = window.setInterval(chequear, INTERVALO_CHEQUEO_MS)

    return () => {
      EVENTOS.forEach((evento) => window.removeEventListener(evento, registrar))
      document.removeEventListener('visibilitychange', chequear)
      window.clearInterval(intervalo)
    }
  }, [activo, onInactivo])
}
