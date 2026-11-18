import { api, type MetaPaginacion } from '../../lib/api'

export interface Cliente {
  id: number
  nombre: string
  telefono: string
  email: string | null
  asegurado: boolean
  created_at: string
}

export interface NuevoCliente {
  nombre: string
  telefono: string
  email: string
}

export interface PaginaClientes {
  clientes: Cliente[]
  meta: MetaPaginacion
}

export type TipoCliente = '' | 'asegurado' | 'particular'

export async function listarClientes(pagina: number, q = '', porPagina?: number, tipo: TipoCliente = '') {
  const { data } = await api.get<PaginaClientes>('/clientes', {
    params: { pagina, q: q || undefined, por_pagina: porPagina, tipo: tipo || undefined },
  })
  return data
}

interface VehiculoResumen {
  id: number
  patente: string
  marca: string | null
  modelo: string | null
}

export interface ClienteDetalle extends Cliente {
  vehiculos: (VehiculoResumen & { anio: number | null })[]
  casos: {
    id: number
    numero_siniestro: string
    fecha_turno: string | null
    orden_id: number | null
    aseguradora: { id: number; nombre: string }
    vehiculo: VehiculoResumen
  }[]
  ordenes: { id: number; estado: string; motivo: string; created_at: string; vehiculo: VehiculoResumen }[]
}

export async function obtenerCliente(id: number) {
  const { data } = await api.get<ClienteDetalle>(`/clientes/${id}`)
  return data
}

export async function registrarCliente(cliente: NuevoCliente) {
  const { data } = await api.post<Cliente>('/clientes', { cliente })
  return data
}
