import { Link } from 'react-router-dom'

export function NoEncontrado() {
  return (
    <main className="login">
      <div className="login-marca">
        <p className="kicker">Gestión de Taller</p>
        <p className="login-titulo">Esa ruta no existe.</p>
      </div>
      <div className="tarjeta formulario">
        <p>La dirección no corresponde a una pantalla del taller.</p>
        <Link to="/">Volver al inicio</Link>
      </div>
    </main>
  )
}
