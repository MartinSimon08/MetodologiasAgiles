import { api, type MetaPaginacion } from '../../lib/api'

export interface Vehiculo {
  id: number
  patente: string
  marca: string | null
  modelo: string | null
  anio: number | null
  kilometraje: number | null
  created_at: string
  cliente: { id: number; nombre: string; telefono: string }
}

export interface NuevoVehiculo {
  cliente_id: number | null
  patente: string
  marca: string
  modelo: string
  anio: string
  kilometraje: string
}

export interface PaginaVehiculos {
  vehiculos: Vehiculo[]
  meta: MetaPaginacion
}

export interface VerificacionPatente {
  patente: string
  existe: boolean
  vehiculo: Vehiculo | null
}

export const normalizarPatente = (patente: string) => patente.toUpperCase().replace(/[\s\-.]/g, '')

export async function listarVehiculos(pagina: number, q = '') {
  const { data } = await api.get<PaginaVehiculos>('/vehiculos', { params: { pagina, q: q || undefined } })
  return data
}

export async function verificarPatente(patente: string) {
  const { data } = await api.get<VerificacionPatente>('/vehiculos/verificar_patente', { params: { patente } })
  return data
}

export async function registrarVehiculo(vehiculo: NuevoVehiculo) {
  const { data } = await api.post<Vehiculo>('/vehiculos', {
    vehiculo: {
      ...vehiculo,
      anio: vehiculo.anio.trim() || null,
      kilometraje: vehiculo.kilometraje.trim() || null,
    },
  })
  return data
}

export async function cambiarDuenio(vehiculoId: number, clienteId: number | null) {
  const { data } = await api.patch<Vehiculo>(`/vehiculos/${vehiculoId}/cambiar_duenio`, {
    vehiculo: { cliente_id: clienteId },
  })
  return data
}
