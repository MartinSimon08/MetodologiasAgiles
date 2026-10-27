import { SelectorTema } from './SelectorTema'
import { useState } from 'react'
import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../features/auth/AuthContext'
import { ROL_LABELS } from '../features/auth/types'
import { NotificacionesTareas } from '../features/tareas/NotificacionesTareas'

export function Layout() {
  const { usuario, logout } = useAuth()
  const [colapsada, setColapsada] = useState(() => {
    try {
      return localStorage.getItem('sidebar-colapsada') === '1'
    } catch {
      return false
    }
  })

  function alternarSidebar() {
    const siguiente = !colapsada
    setColapsada(siguiente)
    try {
      localStorage.setItem('sidebar-colapsada', siguiente ? '1' : '0')
    } catch {
      /* almacenamiento no disponible */
    }
  }

  return (
    <div className={colapsada ? 'app app-colapsada' : 'app'}>
      <button
        type="button"
        className="sidebar-toggle"
        aria-expanded={!colapsada}
        aria-controls="barra-lateral"
        aria-label={colapsada ? 'Expandir menú lateral' : 'Colapsar menú lateral'}
        title={colapsada ? 'Expandir menú' : 'Colapsar menú'}
        onClick={alternarSidebar}
      >
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d={colapsada ? 'M9 5l7 7-7 7' : 'M15 5l-7 7 7 7'} />
        </svg>
      </button>
      <header className="barra" id="barra-lateral">
        <NavLink to="/" className="marca">
          <small>Gestión</small>
          Taller
        </NavLink>
        <nav aria-label="Secciones">
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
          <SelectorTema />
          <span>
            {usuario?.nombre}
            {usuario && <small>{ROL_LABELS[usuario.rol]}</small>}
          </span>
          <button className="secundario" onClick={logout}>
            Salir
          </button>
        </div>
      </header>
      <NotificacionesTareas />
      <main className="contenido">
        <Outlet />
      </main>
    </div>
  )
}
