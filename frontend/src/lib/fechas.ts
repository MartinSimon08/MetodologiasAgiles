function fechaLocalIso(fecha: Date) {
  const anio = fecha.getFullYear()
  const mes = String(fecha.getMonth() + 1).padStart(2, '0')
  const dia = String(fecha.getDate()).padStart(2, '0')
  return `${anio}-${mes}-${dia}`
}

export function hoyIso() {
  return fechaLocalIso(new Date())
}

export function primerDiaDelMesIso() {
  const hoy = new Date()
  return fechaLocalIso(new Date(hoy.getFullYear(), hoy.getMonth(), 1))
}
