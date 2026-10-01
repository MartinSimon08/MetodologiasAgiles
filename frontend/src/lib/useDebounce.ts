import { useEffect, useState } from 'react'

export function useDebounce<T>(valor: T, demoraMs = 300) {
  const [diferido, setDiferido] = useState(valor)

  useEffect(() => {
    const timeout = setTimeout(() => setDiferido(valor), demoraMs)
    return () => clearTimeout(timeout)
  }, [valor, demoraMs])

  return diferido
}
