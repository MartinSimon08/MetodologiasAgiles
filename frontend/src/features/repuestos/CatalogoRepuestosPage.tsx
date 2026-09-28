import { Link } from 'react-router-dom'
import { CatalogoRepuestos } from './CatalogoRepuestos'

export function CatalogoRepuestosPage() {
  return (
    <section className="repuestos">
      <header>
        <h1>Catálogo de repuestos</h1>
        <p className="bajada">Consultá el último costo registrado de cada repuesto.</p>
      </header>
      <p>Para registrar una compra o reutilizar estos datos, abrí una <Link to="/ordenes">orden de trabajo</Link>.</p>
      <CatalogoRepuestos />
    </section>
  )
}
