import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import {
  actualizarConfiguracion,
  obtenerConfiguracion,
  type ConfiguracionTaller,
} from './api'
import { Cargando } from '../../components/Cargando'

const QUERY_KEY = ['configuracion-taller']

function ConfiguracionForm({ configuracion }: { configuracion: ConfiguracionTaller }) {
  const queryClient = useQueryClient()
  const [margen, setMargen] = useState(String(configuracion.margen_repuestos))
  const [cupo, setCupo] = useState(String(configuracion.cupo_diario))
  const [aviso, setAviso] = useState(false)

  const mutation = useMutation({
    mutationFn: actualizarConfiguracion,
    onSuccess: (actualizada) => {
      queryClient.setQueryData(QUERY_KEY, actualizada)
      setMargen(String(actualizada.margen_repuestos))
      setCupo(String(actualizada.cupo_diario))
      setAviso(true)
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setAviso(false)
    mutation.mutate({ margen_repuestos: Number(margen), cupo_diario: Number(cupo) })
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

      <label>
        Cupo diario de ingresos
        <input
          type="number"
          inputMode="numeric"
          min="1"
          step="1"
          value={cupo}
          onChange={(event) => setCupo(event.target.value)}
          required
          aria-describedby="ayuda-cupo"
        />
        <small id="ayuda-cupo">
          Cantidad máxima de vehículos que la turnera acepta por día. Aplica a los turnos que se asignen desde ahora.
        </small>
        <ErroresCampo errores={errores.cupo_diario} />
      </label>

      {mutation.isError && !hayErroresDeCampo && (
        <p className="error" role="alert">
          {errorMessage(mutation.error, 'No se pudo guardar la configuración.')}
        </p>
      )}
      {aviso && (
        <p className="aviso" role="status">
          Se guardó la configuración.
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
      <EncabezadoPagina titulo="Configuración" bajada="Valores generales que usa el taller." />

      {configuracion.isPending && <Cargando />}
      {configuracion.isError && (
        <p className="error" role="alert">
          {errorMessage(configuracion.error, 'No se pudo cargar la configuración.')}
        </p>
      )}
      {configuracion.data && <ConfiguracionForm configuracion={configuracion.data} />}
    </section>
  )
}
