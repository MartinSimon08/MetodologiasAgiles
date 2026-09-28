import { useState, type FormEvent } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { errorMessage } from '../../lib/api'
import { useAuth, type MotivoCierre } from './AuthContext'

const AVISOS_CIERRE: Record<MotivoCierre, string> = {
  inactividad: 'Tu sesión se cerró por inactividad. Volvé a ingresar.',
  expirada: 'Tu sesión expiró. Volvé a ingresar.',
}

export function LoginPage() {
  const { usuario, motivoCierre, login } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [enviando, setEnviando] = useState(false)

  if (usuario) return <Navigate to="/" replace />

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    setEnviando(true)
    try {
      await login(email, password)
      navigate('/', { replace: true })
    } catch (err) {
      setError(errorMessage(err, 'No se pudo iniciar sesión.'))
    } finally {
      setEnviando(false)
    }
  }

  return (
    <main className="login">
      <form className="tarjeta formulario" onSubmit={handleSubmit}>
        <h1>Gestión de Taller</h1>
        {motivoCierre && !error && (
          <p className="aviso" role="status">
            {AVISOS_CIERRE[motivoCierre]}
          </p>
        )}
        <label>
          Email
          <input
            type="email"
            autoComplete="username"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </label>
        <label>
          Contraseña
          <input
            type="password"
            autoComplete="current-password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </label>
        {error && <p className="error" role="alert">{error}</p>}
        <button type="submit" disabled={enviando}>
          {enviando ? 'Ingresando…' : 'Ingresar'}
        </button>
      </form>
    </main>
  )
}
