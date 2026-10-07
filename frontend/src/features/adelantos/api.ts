import { api } from '../../lib/api'

export interface Adelanto {
  id: number
  orden_id: number
  importe: string
  registrado_en: string
  created_at: string
  updated_at: string
}

export interface AdelantosOrden {
  adelantos: Adelanto[]
  saldo: string
}

export async function listarAdelantos(ordenId: number) {
  const { data } = await api.get<AdelantosOrden>(`/ordenes/${ordenId}/adelantos`)
  return data
}

export async function registrarAdelanto(ordenId: number, importe: string) {
  const { data } = await api.post<Adelanto>(`/ordenes/${ordenId}/adelantos`, {
    adelanto: { importe },
  })
  return data
}

function aCentavos(valor: string) {
  const negativo = valor.trim().startsWith('-')
  const [entero, decimal = ''] = valor.trim().replace('-', '').split('.')
  const centavos = Number(entero || '0') * 100 + Number((decimal + '00').slice(0, 2))
  return negativo ? -centavos : centavos
}

export function totalAdelantado(adelantos: { importe: string }[]) {
  const centavos = adelantos.reduce((total, adelanto) => total + aCentavos(adelanto.importe), 0)
  const abs = Math.abs(centavos)
  const signo = centavos < 0 ? '-' : ''
  return `${signo}${Math.trunc(abs / 100)}.${String(abs % 100).padStart(2, '0')}`
}

export function superaSaldo(importeIngresado: string, saldo: string) {
  const texto = importeIngresado.trim()
  if (!texto || texto === '.' || texto === '-') return false
  const centavos = aCentavos(texto)
  if (!Number.isFinite(centavos)) return false
  return centavos > aCentavos(saldo)
}
