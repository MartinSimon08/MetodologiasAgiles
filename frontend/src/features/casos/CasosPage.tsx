import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { BotonNuevo } from '../../components/BotonNuevo'
import { Buscador } from '../../components/Buscador'
import { Cargando } from '../../components/Cargando'
import { EncabezadoPagina } from '../../components/EncabezadoPagina'
import { Paginacion } from '../../components/Paginacion'
import { errorMessage } from '../../lib/api'
import { fechaHora } from '../../lib/formato'
import { useDebounce } from '../../lib/useDebounce'
import { listarCasos } from './api'
import { NuevoCasoForm } from './NuevoCasoForm'

export function CasosPage() {
  const [abriendo, setAbriendo] = useState(false)
  const [aviso, setAviso] = useState<string | null>(null)
  const [busqueda, setBusqueda] = useState('')
  const [pagina, setPagina] = useState(1)
  const buscar = useDebounce(busqueda.trim())

  const casos = useQuery({
    queryKey: ['casos', buscar, pagina],
    queryFn: () => listarCasos(buscar, pagina),
    placeholderData: keepPreviousData,
  })

  return (
    <section className="casos">
      <EncabezadoPagina titulo="Casos" bajada="Siniestros de aseguradoras para planificar antes de que el vehículo ingrese.">
        {!abriendo && (
          <BotonNuevo
            onClick={() => {
              setAviso(null)
              setAbriendo(true)
            }}
          >
            Nuevo caso
          </BotonNuevo>
        )}
      </EncabezadoPagina>

      {aviso && (
        <p className="aviso" role="status">
          {aviso}
        </p>
      )}

      {abriendo && (
        <NuevoCasoForm
          onCancelar={() => setAbriendo(false)}
          onAbierto={(caso) => {
            setAbriendo(false)
            setAviso(`Se abrió el caso ${caso.numero_siniestro} de ${caso.aseguradora.nombre}.`)
          }}
        />
      )}

      <Buscador
        etiqueta="Buscar caso"
        placeholder="Siniestro, patente, asegurado o aseguradora"
        valor={busqueda}
        onCambiar={(valor) => {
          setBusqueda(valor)
          setPagina(1)
        }}
      />

      {casos.isPending && <Cargando />}
      {casos.isError && (
        <p className="error" role="alert">
          {errorMessage(casos.error, 'No se pudieron cargar los casos.')}
        </p>
      )}

      {casos.data?.casos.length === 0 && (
        <p className="estado">{buscar ? 'No hay casos que coincidan.' : 'Todavía no hay casos abiertos.'}</p>
      )}

      {casos.data && casos.data.casos.length > 0 && (
        <>
          <ul className="lista" aria-busy={casos.isPlaceholderData}>
            {casos.data.casos.map((caso) => (
              <li key={caso.id} className="tarjeta item">
                <div className="item-datos">
                  <strong>
                    Siniestro {caso.numero_siniestro} · {caso.aseguradora.nombre}
                  </strong>
                  <span>
                    {caso.asegurado.nombre} · <span className="patente">{caso.vehiculo.patente}</span>
                    {[caso.vehiculo.marca, caso.vehiculo.modelo].filter(Boolean).length > 0 &&
                      ` ${[caso.vehiculo.marca, caso.vehiculo.modelo].filter(Boolean).join(' ')}`}
                  </span>
                  {caso.descripcion && <span>{caso.descripcion}</span>}
                  <span>Abierto el {fechaHora(caso.created_at)}</span>
                </div>
                {caso.fecha_turno === null && <span className="insignia insignia-pendiente">Sin turno</span>}
                {caso.orden_id === null && <span className="insignia insignia-desactivado">Sin orden</span>}
              </li>
            ))}
          </ul>
          <Paginacion meta={casos.data.meta} cargando={casos.isPlaceholderData} onCambiar={setPagina} />
        </>
      )}
    </section>
  )
}
