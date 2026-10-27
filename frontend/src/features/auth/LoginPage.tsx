import { useState, type FormEvent } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { errorMessage } from '../../lib/api'
import { SelectorTema } from '../../components/SelectorTema'
import { useAuth, type MotivoCierre } from './AuthContext'

function OjoAbierto() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M2.5 12S6 6.5 12 6.5 21.5 12 21.5 12 18 17.5 12 17.5 2.5 12 2.5 12z" />
      <circle cx="12" cy="12" r="2.4" />
    </svg>
  )
}

function OjoCerrado() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M2.5 12S6 6.5 12 6.5 21.5 12 21.5 12 18 17.5 12 17.5 2.5 12 2.5 12z" />
      <circle cx="12" cy="12" r="2.4" />
      <path d="M4 19 20 5" />
    </svg>
  )
}

const AVISOS_CIERRE: Record<MotivoCierre, string> = {
  inactividad: 'Tu sesión se cerró por inactividad. Volvé a ingresar.',
  expirada: 'Tu sesión expiró. Volvé a ingresar.',
}

export function LoginPage() {
  const { usuario, motivoCierre, login } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [mostrarPassword, setMostrarPassword] = useState(false)
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
      <div className="login-marca">
        <p className="kicker">Taller mecánico</p>
        <p className="login-titulo">Órdenes, tareas y repuestos del día.</p>
      </div>
      <form className="tarjeta formulario" onSubmit={handleSubmit}>
        <SelectorTema className="selector-tema-login" />
        <p className="kicker">Ingreso</p>
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
        <div className="campo">
          <label htmlFor="password">Contraseña</label>
          <div className="campo-password">
            <input
              id="password"
              type={mostrarPassword ? 'text' : 'password'}
              autoComplete="current-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
            <button
              type="button"
              className="ver-password"
              aria-controls="password"
              aria-pressed={mostrarPassword}
              aria-label={mostrarPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}
              onClick={() => setMostrarPassword((actual) => !actual)}
            >
              {mostrarPassword ? <OjoAbierto /> : <OjoCerrado />}
            </button>
          </div>
        </div>
        {error && <p className="error" role="alert">{error}</p>}
        <button type="submit" disabled={enviando}>
          {enviando ? 'Ingresando…' : 'Ingresar'}
        </button>
      </form>
    </main>
  )
}
