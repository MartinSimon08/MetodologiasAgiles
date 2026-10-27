import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useEffect, useState, type ChangeEvent } from 'react'
import { errorMessage, fieldErrors } from '../../lib/api'
import { adjuntarComprobante, verComprobante, type Repuesto } from './api'
import { Cargando } from '../../components/Cargando'

const TIPOS = new Set(['image/jpeg', 'image/png', 'image/webp'])
const TAMANO_MAXIMO = 8 * 1024 * 1024

export function ComprobanteRepuesto({ ordenId, repuesto, puedeAdjuntar }: {
  ordenId: number
  repuesto: Repuesto
  puedeAdjuntar: boolean
}) {
  const queryClient = useQueryClient()
  const [url, setUrl] = useState<string | null>(null)
  const [visible, setVisible] = useState(false)
  const [cargando, setCargando] = useState(false)
  const [errorCarga, setErrorCarga] = useState<string | null>(null)
  const [errorLocal, setErrorLocal] = useState<string | null>(null)
  const [aviso, setAviso] = useState<string | null>(null)
  const mutation = useMutation({
    mutationFn: (archivo: File) => adjuntarComprobante(ordenId, repuesto.id, archivo),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['repuestos', ordenId] })
      setErrorLocal(null)
      setVisible(false)
      setUrl(null)
      setAviso('Foto del comprobante guardada.')
    },
  })

  useEffect(() => {
    if (!url) return
    return () => URL.revokeObjectURL(url)
  }, [url])

  if (!puedeAdjuntar && !repuesto.comprobante) return null

  const errores = fieldErrors(mutation.error)
  const mensaje = errorLocal
    ?? errores.comprobante?.join('. ')
    ?? errores.orden?.join('. ')
    ?? errores.estado?.join('. ')
    ?? (mutation.isError ? errorMessage(mutation.error, 'No se pudo guardar la foto.') : null)

  async function mostrar() {
    setVisible(true)
    setAviso(null)
    if (url) return
    setCargando(true)
    setErrorCarga(null)
    try {
      setUrl(URL.createObjectURL(await verComprobante(ordenId, repuesto.id)))
    } catch (error) {
      setErrorCarga(errorMessage(error, 'No se pudo abrir el comprobante.'))
    } finally {
      setCargando(false)
    }
  }

  function elegir(event: ChangeEvent<HTMLInputElement>) {
    const archivo = event.target.files?.[0]
    event.target.value = ''
    if (!archivo) return
    if (archivo.type && !TIPOS.has(archivo.type)) {
      setErrorLocal('Foto del comprobante tiene que ser JPG, PNG o WebP')
      return
    }
    if (archivo.size > TAMANO_MAXIMO) {
      setErrorLocal('Foto del comprobante no puede superar 8 MB')
      return
    }
    setErrorLocal(null)
    setAviso(null)
    mutation.mutate(archivo)
  }

  return (
    <div className="comprobante">
      {repuesto.comprobante && <span className="comprobante-nombre">{repuesto.comprobante.nombre}</span>}
      <div className="comprobante-acciones">
        {repuesto.comprobante && (
          <button type="button" className="secundario" onClick={() => void mostrar()}>Ver comprobante</button>
        )}
        {puedeAdjuntar && (
          <label className="boton-archivo">
            {mutation.isPending ? 'Subiendo…' : repuesto.comprobante ? 'Reemplazar foto' : 'Adjuntar foto'}
            <input type="file" accept="image/jpeg,image/png,image/webp" disabled={mutation.isPending} onChange={elegir} />
          </label>
        )}
      </div>
      {aviso && <p className="aviso" role="status">{aviso}</p>}
      {mensaje && <p className="error" role="alert">{mensaje}</p>}
      {visible && (
        <div className="comprobante-vista">
          {cargando && <Cargando />}
          {errorCarga && <p className="error" role="alert">{errorCarga}</p>}
          {url && <img src={url} alt={`Comprobante de ${repuesto.descripcion}`} />}
          <button type="button" className="secundario" onClick={() => setVisible(false)}>Cerrar</button>
        </div>
      )}
    </div>
  )
}
