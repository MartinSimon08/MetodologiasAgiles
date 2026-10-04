function enteroConEscala(valor: string, escala: number): bigint | null {
  const coincidencia = valor.trim().match(/^(\d+)(?:\.(\d+))?$/)
  if (!coincidencia) return null
  const fraccion = coincidencia[2] ?? ''
  if (fraccion.length > escala) return null
  return BigInt(coincidencia[1] + fraccion.padEnd(escala, '0'))
}

function centavosAImporte(centavos: bigint): string {
  const entero = centavos / 100n
  const fraccion = (centavos % 100n).toString().padStart(2, '0')
  return `${entero}.${fraccion}`
}

export function calcularPrecioRepuesto(costo: string, cantidad: string, margen: string) {
  const costoCentavos = enteroConEscala(costo, 2)
  const margenCentesimos = enteroConEscala(margen, 2)
  if (costoCentavos === null || margenCentesimos === null || margenCentesimos > 10000n) return null
  if (!/^\d+$/.test(cantidad.trim())) return null
  const unidades = BigInt(cantidad.trim())
  if (unidades <= 0n || unidades > 2147483647n) return null

  const numerador = costoCentavos * unidades * (10000n + margenCentesimos)
  const precioCentavos = (numerador + 5000n) / 10000n
  return {
    precio: centavosAImporte(precioCentavos),
    ganancia: centavosAImporte(precioCentavos - costoCentavos * unidades),
  }
}
