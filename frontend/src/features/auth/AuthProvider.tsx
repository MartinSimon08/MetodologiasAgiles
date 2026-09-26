import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { onUnauthorized, tokenStorage } from '../../lib/api'
import { iniciarSesion, obtenerSesion } from './api'
import { AuthContext, type AuthState } from './AuthContext'

export function AuthProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient()
  const [token, setToken] = useState(tokenStorage.get)

  const sesion = useQuery({
    queryKey: ['sesion', token],
    queryFn: obtenerSesion,
    enabled: token !== null,
    retry: false,
    staleTime: Infinity,
  })

  const logout = useCallback(() => {
    tokenStorage.clear()
    setToken(null)
    queryClient.clear()
  }, [queryClient])

  useEffect(() => onUnauthorized(logout), [logout])

  const login = useCallback(
    async (email: string, password: string) => {
      const nuevoToken = await iniciarSesion(email, password)
      tokenStorage.set(nuevoToken)
      await queryClient.fetchQuery({ queryKey: ['sesion', nuevoToken], queryFn: obtenerSesion })
      setToken(nuevoToken)
    },
    [queryClient],
  )

  const value = useMemo<AuthState>(
    () => ({
      usuario: token ? (sesion.data ?? null) : null,
      cargando: token !== null && sesion.isPending,
      login,
      logout,
    }),
    [token, sesion.data, sesion.isPending, login, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
