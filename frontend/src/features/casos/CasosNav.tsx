import { NavLink } from 'react-router-dom'

export function CasosNav() {
  return (
    <nav className="subnav" aria-label="Secciones de casos">
      <NavLink to="/casos" end>
        Casos
      </NavLink>
      <NavLink to="/casos/aseguradora">Por aseguradora</NavLink>
    </nav>
  )
}
