import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { ErroresCampo } from '../../components/ErroresCampo'
import { errorMessage, fieldErrors } from '../../lib/api'
import { AseguradoraSelector } from '../aseguradoras/AseguradoraSelector'
import { ClienteSelector } from '../clientes/ClienteSelector'
import { listarVehiculosDeCliente } from '../vehiculos/api'
import { abrirCaso, DESCRIPCION_MAXIMA, NUMERO_SINIESTRO_MAXIMO, type Caso, type NuevoCaso } from './api'

interface Props {
  onAbierto: (caso: Caso) => void
  onCancelar: () => void
}

export function NuevoCasoForm({ onAbierto, onCancelar }: Props) {
  const queryClient = useQueryClient()
  const [datos, setDatos] = useState<NuevoCaso>({
    aseguradora_id: null,
    asegurado_id: null,
    vehiculo_id: null,
    numero_siniestro: '',
    descripcion: '',
  })

  const vehiculos = useQuery({
    queryKey: ['vehiculos', 'cliente', datos.asegurado_id],
    queryFn: () => listarVehiculosDeCliente(datos.asegurado_id!),
    enabled: datos.asegurado_id !== null,
  })

  const mutation = useMutation({
    mutationFn: abrirCaso,
    onSuccess: (caso) => {
      queryClient.invalidateQueries({ queryKey: ['casos'] })
      onAbierto(caso)
    },
  })

  const errores = fieldErrors(mutation.error)
  const hayErroresDeCampo = Object.keys(errores).length > 0
  const vehiculoUnico = vehiculos.data?.length === 1 ? vehiculos.data[0].id : null
  const vehiculoId = datos.vehiculo_id ?? vehiculoUnico
  const completo =
    datos.aseguradora_id !== null && datos.asegurado_id !== null && vehiculoId !== null && datos.numero_siniestro.trim() !== ''

  function actualizar<K extends keyof NuevoCaso>(campo: K, valor: NuevoCaso[K]) {
    setDatos((previo) => ({ ...previo, [campo]: valor }))
  }

  function cambiarAsegurado(aseguradoId: number | null) {
    setDatos((previo) => ({ ...previo, asegurado_id: aseguradoId, vehiculo_id: null }))
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    mutation.mutate({ ...datos, vehiculo_id: vehiculoId })
  }

  return (
    <form className="tarjeta formulario nueva-orden" onSubmit={handleSubmit} noValidate>
      <h2>Nuevo caso de siniestro</h2>
      <AseguradoraSelector
        etiqueta="Aseguradora"
        valor={datos.aseguradora_id}
        onCambiar={(id) => actualizar('aseguradora_id', id)}
        errores={errores.aseguradora}
        autoFocus
      />
      <ClienteSelector
        etiqueta="Asegurado"
        valor={datos.asegurado_id}
        onCambiar={cambiarAsegurado}
        errores={errores.asegurado}
      />
      {datos.asegurado_id !== null && (
        <label>
          Vehículo
          {vehiculos.isPending && <span className="estado">Cargando vehículos…</span>}
          {vehiculos.isError && (
            <span className="error" role="alert">
              {errorMessage(vehiculos.error, 'No se pudieron cargar los vehículos.')}
            </span>
          )}
          {vehiculos.data && vehiculos.data.length > 0 && (
            <select
              value={vehiculoId ?? ''}
              onChange={(e) => actualizar('vehiculo_id', e.target.value ? Number(e.target.value) : null)}
              required
            >
              {vehiculoUnico === null && <option value="">Elegí un vehículo</option>}
              {vehiculos.data.map((vehiculo) => (
                <option key={vehiculo.id} value={vehiculo.id}>
                  {[vehiculo.patente, vehiculo.marca, vehiculo.modelo].filter(Boolean).join(' ')}
                </option>
              ))}
            </select>
          )}
          {vehiculos.data?.length === 0 && (
            <small>
              El asegurado no tiene vehículos. Registralo primero en <Link to="/vehiculos">Vehículos</Link>.
            </small>
          )}
          <ErroresCampo errores={errores.vehiculo} />
        </label>
      )}
      <label>
        Número de siniestro
        <input
          autoComplete="off"
          value={datos.numero_siniestro}
          onChange={(e) => actualizar('numero_siniestro', e.target.value)}
          required
          maxLength={NUMERO_SINIESTRO_MAXIMO}
        />
        <ErroresCampo errores={errores.numero_siniestro} />
      </label>
      <label>
        Descripción (opcional)
        <textarea
          rows={3}
          maxLength={DESCRIPCION_MAXIMA}
          value={datos.descripcion}
          onChange={(e) => actualizar('descripcion', e.target.value)}
        />
        <small>El caso queda sin turno y sin orden hasta que el vehículo ingrese al taller.</small>
        <ErroresCampo errores={errores.descripcion} />
      </label>
      {mutation.isError && !hayErroresDeCampo && (
        <p className="error" role="alert">
          {errorMessage(mutation.error, 'No se pudo abrir el caso.')}
        </p>
      )}
      <div className="acciones">
        <button type="button" className="secundario" disabled={mutation.isPending} onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" disabled={mutation.isPending || !completo}>
          {mutation.isPending ? 'Abriendo…' : 'Abrir caso'}
        </button>
      </div>
    </form>
  )
}
