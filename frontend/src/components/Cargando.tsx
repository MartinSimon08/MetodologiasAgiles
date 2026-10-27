export function Cargando({ pantalla = false }: { pantalla?: boolean }) {
  return (
    <div className={pantalla ? 'cargando cargando-pantalla' : 'cargando'} role="status" aria-live="polite">
      {pantalla && (
        <p className="cargando-marca">
          <small>Gestión</small>
          Taller
        </p>
      )}
      <span className="cargando-pista" aria-hidden="true">
        <span className="cargando-barra" />
      </span>
      <span className="solo-lectores">Cargando…</span>
    </div>
  )
}
