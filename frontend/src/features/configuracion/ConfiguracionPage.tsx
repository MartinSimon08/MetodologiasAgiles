import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import {
  actualizarConfiguracion,
  obtenerConfiguracion,
  type ConfiguracionTaller,
} from './api'

const QUERY_KEY = ['configuracion-taller']

function MargenForm({ configuracion }: { configuracion: ConfiguracionTaller }) {
  const queryClient = useQueryClient()
  const [margen, setMargen] = useState(String(configuracion.margen_repuestos))
  const [aviso, setAviso] = useState(false)

  const mutation = useMutation({
    mutationFn: actualizarConfiguracion,
    onSuccess: (actualizada) => {
      queryClient.setQueryData(QUERY_KEY, actualizada)
      setMargen(String(actualizada.margen_repuestos))
      setAviso(true)
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setAviso(false)
    mutation.mutate(Number(margen))
  }

  return (
    <form className="tarjeta formulario configuracion-form" onSubmit={handleSubmit}>
      <label>
        Margen por defecto para repuestos
        <span className="campo-porcentaje">
          <input
            type="number"
            inputMode="decimal"
            min="0"
            max="100"
            step="0.01"
            value={margen}
            onChange={(event) => setMargen(event.target.value)}
            required
            aria-describedby="ayuda-margen"
          />
          <span aria-hidden="true">%</span>
        </span>
        <small id="ayuda-margen">
          Se aplicará a los repuestos nuevos. Podrás cambiarlo al cargar cada repuesto.
        </small>
        <ErroresCampo errores={errores.margen_repuestos} />
      </label>

      {mutation.isError && !hayErroresDeCampo && (
        <p className="error" role="alert">
          {errorMessage(mutation.error, 'No se pudo guardar el margen.')}
        </p>
      )}
      {aviso && (
        <p className="aviso" role="status">
          Se guardó el margen por defecto.
        </p>
      )}

      <div className="acciones">
        <button type="submit" disabled={mutation.isPending}>
          {mutation.isPending ? 'Guardando…' : 'Guardar cambios'}
        </button>
      </div>
    </form>
  )
}

export function ConfiguracionPage() {
  const configuracion = useQuery({
    queryKey: QUERY_KEY,
    queryFn: obtenerConfiguracion,
  })

  return (
    <section className="configuracion">
      <header className="encabezado">
        <div>
          <h1>Configuración</h1>
          <p className="bajada">Valores generales que usa el taller.</p>
        </div>
      </header>

      {configuracion.isPending && <p className="estado">Cargando configuración…</p>}
      {configuracion.isError && (
        <p className="error" role="alert">
          {errorMessage(configuracion.error, 'No se pudo cargar la configuración.')}
        </p>
      )}
      {configuracion.data && <MargenForm configuracion={configuracion.data} />}
    </section>
  )
}
