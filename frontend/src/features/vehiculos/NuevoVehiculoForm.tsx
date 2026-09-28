import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { ClienteSelector } from '../clientes/ClienteSelector'
import { registrarVehiculo, type NuevoVehiculo, type Vehiculo } from './api'

const VACIO: NuevoVehiculo = {
  cliente_id: null,
  patente: '',
  marca: '',
  modelo: '',
  anio: '',
  kilometraje: '',
}

interface Props {
  onRegistrado: (vehiculo: Vehiculo) => void
  onCancelar: () => void
}

export function NuevoVehiculoForm({ onRegistrado, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [datos, setDatos] = useState<NuevoVehiculo>(VACIO)

  const mutation = useMutation({
    mutationFn: registrarVehiculo,
    onSuccess: (vehiculo) => {
      queryClient.invalidateQueries({ queryKey: ['vehiculos'] })
      setDatos(VACIO)
      onRegistrado(vehiculo)
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0

  function actualizar<K extends keyof NuevoVehiculo>(campo: K, valor: NuevoVehiculo[K]) {
    setDatos((previo) => ({ ...previo, [campo]: valor }))
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate(datos)
  }

  return (
    <form className="tarjeta formulario" onSubmit={handleSubmit} noValidate>
      <h2>Nuevo vehículo</h2>
      <ClienteSelector
        etiqueta="Dueño"
        valor={datos.cliente_id}
        onCambiar={(clienteId) => actualizar('cliente_id', clienteId)}
        errores={errores.cliente}
        autoFocus
      />
      <label>
        Patente
        <input
          autoComplete="off"
          autoCapitalize="characters"
          value={datos.patente}
          onChange={(e) => actualizar('patente', e.target.value)}
          required
        />
        <small>Obligatoria. Ej.: AB 123 CD o ABC 123.</small>
        <ErroresCampo errores={errores.patente} />
      </label>
      <div className="campos-vehiculo">
        <label>
          Marca
          <input autoComplete="off" value={datos.marca} onChange={(e) => actualizar('marca', e.target.value)} />
          <ErroresCampo errores={errores.marca} />
        </label>
        <label>
          Modelo
          <input autoComplete="off" value={datos.modelo} onChange={(e) => actualizar('modelo', e.target.value)} />
          <ErroresCampo errores={errores.modelo} />
        </label>
        <label>
          Año
          <input
            type="number"
            inputMode="numeric"
            min={1900}
            value={datos.anio}
            onChange={(e) => actualizar('anio', e.target.value)}
          />
          <ErroresCampo errores={errores.anio} />
        </label>
        <label>
          Kilometraje
          <input
            type="number"
            inputMode="numeric"
            min={0}
            value={datos.kilometraje}
            onChange={(e) => actualizar('kilometraje', e.target.value)}
          />
          <ErroresCampo errores={errores.kilometraje} />
        </label>
      </div>
      {mutation.isError && !hayErroresDeCampo && (
        <p className="error" role="alert">{errorMessage(mutation.error)}</p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending}>
          {mutation.isPending ? 'Registrando…' : 'Registrar vehículo'}
        </button>
      </div>
    </form>
  )
}
