import { NavLink } from 'react-router-dom'

export function RepuestosNav() {
  return (
    <nav className="subnav" aria-label="Secciones de repuestos">
      <NavLink to="/repuestos" end>
        Catálogo
      </NavLink>
      <NavLink to="/repuestos/proveedores">Por proveedor</NavLink>
    </nav>
  )
}
