import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../features/auth/AuthContext'
import { ROL_LABELS } from '../features/auth/types'

export function Layout() {
  const { usuario, logout } = useAuth()

  return (
    <div className="app">
      <header className="barra">
        <NavLink to="/" className="marca">
          <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z" />
          </svg>
          Taller
        </NavLink>
        <nav>
          {usuario?.rol === 'mecanico' && <NavLink to="/mis-tareas">Mis tareas</NavLink>}
          <NavLink to="/ordenes">Órdenes</NavLink>
          {usuario?.rol === 'administrador' && (
            <>
              <NavLink to="/clientes">Clientes</NavLink>
              <NavLink to="/vehiculos">Vehículos</NavLink>
              <NavLink to="/repuestos">Repuestos</NavLink>
              <NavLink to="/usuarios">Usuarios</NavLink>
              <NavLink to="/tareas-frecuentes">Tareas frecuentes</NavLink>
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
