import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { onUnauthorized, TOKEN_KEY, tokenStorage } from '../../lib/api'
import { iniciarSesion, obtenerSesion } from './api'
import { AuthContext, type AuthState, type MotivoCierre } from './AuthContext'
import { ultimaActividad, useCierrePorInactividad } from './inactividad'

export function AuthProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient()
  const [token, setToken] = useState(tokenStorage.get)
  const [motivoCierre, setMotivoCierre] = useState<MotivoCierre | null>(null)

  const sesion = useQuery({
    queryKey: ['sesion', token],
    queryFn: obtenerSesion,
    enabled: token !== null,
    retry: false,
    staleTime: Infinity,
  })

  const cerrarSesion = useCallback(
    (motivo: MotivoCierre | null) => {
      tokenStorage.clear()
      setToken(null)
      setMotivoCierre(motivo)
      queryClient.clear()
    },
    [queryClient],
  )

  const logout = useCallback(() => cerrarSesion(null), [cerrarSesion])
  const cerrarPorInactividad = useCallback(() => cerrarSesion('inactividad'), [cerrarSesion])

  useEffect(() => onUnauthorized(() => cerrarSesion('expirada')), [cerrarSesion])

  useEffect(() => {
    function sincronizar(event: StorageEvent) {
      if (event.key === null || (event.key === TOKEN_KEY && event.newValue === null)) {
        if (token !== null) cerrarSesion(null)
      }
    }
    window.addEventListener('storage', sincronizar)
    return () => window.removeEventListener('storage', sincronizar)
  }, [token, cerrarSesion])

  useCierrePorInactividad(token !== null, cerrarPorInactividad)

  const login = useCallback(
    async (email: string, password: string) => {
      const nuevoToken = await iniciarSesion(email, password)
      tokenStorage.set(nuevoToken)
      ultimaActividad.registrar()
      await queryClient.fetchQuery({ queryKey: ['sesion', nuevoToken], queryFn: obtenerSesion })
      setMotivoCierre(null)
      setToken(nuevoToken)
    },
    [queryClient],
  )

  const value = useMemo<AuthState>(
    () => ({
      usuario: token ? (sesion.data ?? null) : null,
      cargando: token !== null && sesion.isPending,
      motivoCierre,
      login,
      logout,
    }),
    [token, sesion.data, sesion.isPending, motivoCierre, login, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
