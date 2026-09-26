export function ErroresCampo({ errores }: { errores?: string[] }) {
  if (!errores?.length) return null
  return <span className="error">{errores.join('. ')}</span>
}
