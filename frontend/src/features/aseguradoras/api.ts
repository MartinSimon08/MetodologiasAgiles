import { api, type MetaPaginacion } from '../../lib/api'

export interface Aseguradora {
  id: number
  nombre: string
  telefono: string | null
  email: string | null
  activa: boolean
  created_at: string
}

export interface DatosAseguradora {
  nombre: string
  telefono: string
  email: string
}

export interface PaginaAseguradoras {
  aseguradoras: Aseguradora[]
  meta: MetaPaginacion
}

export async function listarAseguradoras(buscar: string, pagina: number) {
  const { data } = await api.get<PaginaAseguradoras>('/aseguradoras', {
    params: { buscar: buscar || undefined, pagina },
  })
  return data
}

export async function guardarAseguradora(aseguradora: DatosAseguradora, id?: number) {
  const { data } = id === undefined
    ? await api.post<Aseguradora>('/aseguradoras', { aseguradora })
    : await api.patch<Aseguradora>(`/aseguradoras/${id}`, { aseguradora })
  return data
}

export async function cambiarEstadoAseguradora(id: number, activa: boolean) {
  const { data } = await api.patch<Aseguradora>(`/aseguradoras/${id}/${activa ? 'activar' : 'desactivar'}`)
  return data
}

export async function eliminarAseguradora(id: number) {
  await api.delete(`/aseguradoras/${id}`)
}
