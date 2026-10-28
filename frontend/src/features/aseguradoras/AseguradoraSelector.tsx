import { SelectorBuscable } from '../../components/SelectorBuscable'
import { listarAseguradoras, type Aseguradora } from './api'

interface Props {
  etiqueta: string
  valor: number | null
  onCambiar: (aseguradoraId: number | null) => void
  errores?: string[]
  autoFocus?: boolean
}

async function cargar(pagina: number, q: string) {
  const { aseguradoras, meta } = await listarAseguradoras(q, pagina, true)
  return { items: aseguradoras, meta }
}

export function AseguradoraSelector(props: Props) {
  return (
    <SelectorBuscable<Aseguradora>
      {...props}
      placeholder="Nombre de la aseguradora"
      queryKey="aseguradoras"
      cargar={cargar}
      describir={(aseguradora) => (
        <>
          <strong>{aseguradora.nombre}</strong>
          <span>{[aseguradora.telefono, aseguradora.email].filter(Boolean).join(' · ') || 'Sin contacto cargado'}</span>
        </>
      )}
      textos={{
        cargando: 'Cargando aseguradoras…',
        sinResultados: 'Ninguna aseguradora activa coincide con la búsqueda.',
        error: 'No se pudieron cargar las aseguradoras.',
      }}
    />
  )
}
