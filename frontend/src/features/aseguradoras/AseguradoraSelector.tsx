import { SelectorBuscable } from '../../components/SelectorBuscable'
import { listarAseguradoras, type Aseguradora } from './api'

interface Props {
  etiqueta: string
  valor: number | null
  inicial?: Aseguradora | null
  incluirDesactivadas?: boolean
  onCambiar: (aseguradoraId: number | null) => void
  errores?: string[]
  autoFocus?: boolean
}

export function AseguradoraSelector({ incluirDesactivadas = false, ...props }: Props) {
  async function cargar(pagina: number, q: string) {
    const { aseguradoras, meta } = await listarAseguradoras(q, pagina, !incluirDesactivadas)
    return { items: aseguradoras, meta }
  }

  return (
    <SelectorBuscable<Aseguradora>
      {...props}
      placeholder="Nombre de la aseguradora"
      queryKey={incluirDesactivadas ? 'aseguradoras-todas' : 'aseguradoras'}
      cargar={cargar}
      describir={(aseguradora) => (
        <>
          <strong>{aseguradora.nombre}</strong>
          <span>{[aseguradora.telefono, aseguradora.email].filter(Boolean).join(' · ') || 'Sin contacto cargado'}</span>
          {!aseguradora.activa && <span className="insignia insignia-desactivado">Desactivada</span>}
        </>
      )}
      textos={{
        cargando: 'Cargando aseguradoras…',
        sinResultados: incluirDesactivadas
          ? 'Ninguna aseguradora coincide con la búsqueda.'
          : 'Ninguna aseguradora activa coincide con la búsqueda.',
        error: 'No se pudieron cargar las aseguradoras.',
      }}
    />
  )
}
