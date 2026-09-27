import { api } from '../../lib/api'

export interface ConfiguracionTaller {
  margen_repuestos: number
}

export async function obtenerConfiguracion() {
  const { data } = await api.get<ConfiguracionTaller>('/configuracion_taller')
  return data
}

export async function actualizarConfiguracion(margenRepuestos: number) {
  const { data } = await api.patch<ConfiguracionTaller>('/configuracion_taller', {
    configuracion_taller: { margen_repuestos: margenRepuestos },
  })
  return data
}
