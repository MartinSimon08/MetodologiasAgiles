import { useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { errorMessage } from '../../lib/api'
import { CatalogoRepuestos } from './CatalogoRepuestos'
import { RepuestoCatalogoForm } from './RepuestoCatalogoForm'
import { eliminarCatalogo, type RepuestoCatalogo } from './api'

export function CatalogoRepuestosPage() {
  const [editando, setEditando] = useState<RepuestoCatalogo | null | undefined>(undefined)
  const [aviso, setAviso] = useState('')
  const queryClient = useQueryClient()
  const eliminar = useMutation({
    mutationFn: eliminarCatalogo,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['repuestos-catalogo'] })
      setAviso('Repuesto eliminado del catálogo.')
    },
  })
  const puedeGestionar = editando === undefined && !eliminar.isPending

  function confirmarEliminacion(repuesto: RepuestoCatalogo) {
    if (!window.confirm(`¿Eliminar "${repuesto.nombre}" del catálogo? Los repuestos ya cargados en órdenes se conservarán.`)) return
    setAviso('')
    eliminar.mutate(repuesto.id)
  }

  return (
    <section className="repuestos">
      <header>
        <h1>Catálogo de repuestos</h1>
        <p className="bajada">Cargá repuestos y sus precios para autocompletar las órdenes.</p>
      </header>
      <button type="button" onClick={() => {
        setAviso('')
        eliminar.reset()
        setEditando(null)
      }} disabled={!puedeGestionar}>Nuevo repuesto</button>
      {aviso && <p className="aviso" role="status">{aviso}</p>}
      {eliminar.isPending && <p className="estado" role="status">Eliminando repuesto…</p>}
      {eliminar.isError && <p className="error" role="alert">
        {errorMessage(eliminar.error, 'No se pudo eliminar el repuesto del catálogo.')}
      </p>}
      {editando !== undefined && <RepuestoCatalogoForm key={editando?.id ?? 'nuevo'}
        repuesto={editando ?? undefined} onCancelar={() => setEditando(undefined)} onGuardado={() => {
          setEditando(undefined)
          setAviso('Repuesto guardado en el catálogo.')
        }} />}
      <CatalogoRepuestos onEditar={puedeGestionar ? (repuesto) => {
        setAviso('')
        eliminar.reset()
        setEditando(repuesto)
      } : undefined} onEliminar={puedeGestionar ? confirmarEliminacion : undefined} />
    </section>
  )
}
