import { NavLink } from 'react-router-dom'

export function ReportesNav() {
  return (
    <nav className="subnav" aria-label="Reportes">
      <NavLink to="/reportes/ordenes-por-periodo">Órdenes abiertas y cerradas</NavLink>
      <NavLink to="/reportes/tareas-por-mecanico">Tareas por mecánico</NavLink>
      <NavLink to="/reportes/margen-repuestos">Margen de repuestos</NavLink>
      <NavLink to="/reportes/tareas-frecuentes">Tareas frecuentes</NavLink>
    </nav>
  )
}
