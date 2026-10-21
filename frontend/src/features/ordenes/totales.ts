import type { QueryClient } from '@tanstack/react-query'

export function invalidarTotalesOrden(queryClient: QueryClient, ordenId: number) {
  queryClient.invalidateQueries({ queryKey: ['total-parcial', ordenId] })
  queryClient.invalidateQueries({ queryKey: ['resumen-cierre', ordenId] })
  queryClient.invalidateQueries({ queryKey: ['adelantos', ordenId] })
}
