import { api, type MetaPaginacion } from '../../lib/api'

export interface Cliente {
  id: number
  nombre: string
  telefono: string
  email: string | null
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

export async function listarClientes(pagina: number, q = '', porPagina?: number) {
  const { data } = await api.get<PaginaClientes>('/clientes', {
    params: {
      pagina,
      ...(q ? { q } : {}),
      ...(porPagina ? { por_pagina: porPagina } : {}),
    },
  })
  return data
}

export async function registrarCliente(cliente: NuevoCliente) {
  const { data } = await api.post<Cliente>('/clientes', { cliente })
  return data
}
