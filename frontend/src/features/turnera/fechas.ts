export function desdeIso(iso: string) {
  const [anio, mes, dia] = iso.split('-').map(Number)
  return new Date(anio, mes - 1, dia)
}

export function aIso(fecha: Date) {
  const mes = String(fecha.getMonth() + 1).padStart(2, '0')
  const dia = String(fecha.getDate()).padStart(2, '0')
  return `${fecha.getFullYear()}-${mes}-${dia}`
}

export function sumarDias(iso: string, dias: number) {
  const fecha = desdeIso(iso)
  fecha.setDate(fecha.getDate() + dias)
  return aIso(fecha)
}

export function primerDiaDelMes(iso: string, mesesDesplazados = 0) {
  const fecha = desdeIso(iso)
  return aIso(new Date(fecha.getFullYear(), fecha.getMonth() + mesesDesplazados, 1))
}

export function mismoMes(iso: string, otroIso: string) {
  return iso.slice(0, 7) === otroIso.slice(0, 7)
}

function capitalizar(texto: string) {
  return texto.charAt(0).toUpperCase() + texto.slice(1)
}

export function nombreDia(iso: string) {
  return capitalizar(desdeIso(iso).toLocaleDateString('es-AR', { weekday: 'long', day: 'numeric', month: 'long' }))
}

export function nombreMes(iso: string) {
  return capitalizar(desdeIso(iso).toLocaleDateString('es-AR', { month: 'long', year: 'numeric' }))
}

export function fechaCorta(iso: string) {
  return desdeIso(iso).toLocaleDateString('es-AR', { day: '2-digit', month: '2-digit' })
}
