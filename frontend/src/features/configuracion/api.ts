import { api } from '../../lib/api'

export interface ConfiguracionTaller {
  margen_repuestos: number
  cupo_diario: number
}

export async function obtenerConfiguracion() {
  const { data } = await api.get<ConfiguracionTaller>('/configuracion_taller')
  return data
}

export async function actualizarConfiguracion(cambios: Partial<ConfiguracionTaller>) {
  const { data } = await api.patch<ConfiguracionTaller>('/configuracion_taller', {
    configuracion_taller: cambios,
  })
  return data
}
