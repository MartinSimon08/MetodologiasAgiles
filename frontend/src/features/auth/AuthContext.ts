import { createContext, useContext } from 'react'
import type { Usuario } from './types'

export type MotivoCierre = 'inactividad' | 'expirada'

export interface AuthState {
  usuario: Usuario | null
  cargando: boolean
  motivoCierre: MotivoCierre | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

export const AuthContext = createContext<AuthState | null>(null)

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth debe usarse dentro de AuthProvider')
  return context
}
