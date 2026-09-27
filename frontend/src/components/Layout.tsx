import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../features/auth/AuthContext'
import { ROL_LABELS } from '../features/auth/types'

export function Layout() {
  const { usuario, logout } = useAuth()

  return (
    <div className="app">
      <header className="barra">
        <NavLink to="/" className="marca">
          Taller
        </NavLink>
        <nav>
          <NavLink to="/ordenes">Órdenes</NavLink>
          {usuario?.rol === 'administrador' && (
            <>
              <NavLink to="/clientes">Clientes</NavLink>
              <NavLink to="/usuarios">Usuarios</NavLink>
              <NavLink to="/configuracion">Configuración</NavLink>
            </>
          )}
        </nav>
        <div className="sesion">
          <span>
            {usuario?.nombre}
            {usuario && <small>{ROL_LABELS[usuario.rol]}</small>}
          </span>
          <button className="secundario" onClick={logout}>
            Salir
          </button>
        </div>
      </header>
      <main className="contenido">
        <Outlet />
      </main>
    </div>
  )
}
