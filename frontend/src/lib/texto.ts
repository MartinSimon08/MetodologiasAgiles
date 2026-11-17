function normalizar(texto: string) {
  return texto.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase()
}

export function coincide(termino: string, ...campos: (string | null | undefined)[]) {
  const buscado = normalizar(termino.trim())
  if (!buscado) return true
  return campos.some((campo) => campo && normalizar(campo).includes(buscado))
}
