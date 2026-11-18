interface VehiculoEtiqueta {
  patente: string
  marca?: string | null
  modelo?: string | null
}

export function etiquetaVehiculo(vehiculo: VehiculoEtiqueta) {
  const detalle = [vehiculo.marca, vehiculo.modelo].filter(Boolean).join(' ')
  return detalle ? `${vehiculo.patente} · ${detalle}` : vehiculo.patente
}
