export interface AvisoCasoListoParaRetirar {
  tipo: 'caso_listo_para_retirar'
  caso_id: number
  numero_siniestro: string
  orden_id: number
  vehiculo: { id: number; patente: string; marca: string | null; modelo: string | null; anio: number | null }
  aseguradora: { id: number; nombre: string }
}
