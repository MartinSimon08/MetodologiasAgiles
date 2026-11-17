import { useState } from 'react'
import type { MetaPaginacion } from './api'

export const OPCIONES_POR_PAGINA = [10, 15, 20, 25] as const
export const POR_PAGINA_DEFAULT = 10

const CLAVE = 'taller.porPagina'

function leerPreferencia() {
  try {
    const guardado = Number(localStorage.getItem(CLAVE))
    return OPCIONES_POR_PAGINA.find((opcion) => opcion === guardado) ?? POR_PAGINA_DEFAULT
  } catch {
    return POR_PAGINA_DEFAULT
  }
}

export function usePorPagina() {
  const [porPagina, setPorPagina] = useState<number>(leerPreferencia)

  function cambiar(valor: number) {
    setPorPagina(valor)
    try {
      localStorage.setItem(CLAVE, String(valor))
    } catch {
      return
    }
  }

  return [porPagina, cambiar] as const
}

export function paginarLocal<T>(items: T[], pagina: number, porPagina: number) {
  const totalPaginas = Math.max(1, Math.ceil(items.length / porPagina))
  const actual = Math.min(Math.max(1, pagina), totalPaginas)
  const desde = (actual - 1) * porPagina
  const meta: MetaPaginacion = {
    pagina: actual,
    por_pagina: porPagina,
    total: items.length,
    total_paginas: totalPaginas,
  }
  return { items: items.slice(desde, desde + porPagina), desde, meta }
}
