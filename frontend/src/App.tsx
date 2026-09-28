import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { InicioPage } from './components/InicioPage'
import { Layout } from './components/Layout'
import { ClientesPage } from './features/clientes/ClientesPage'
import { ConfiguracionPage } from './features/configuracion/ConfiguracionPage'
import { LoginPage } from './features/auth/LoginPage'
import { RequireAuth } from './features/auth/RequireAuth'
import { OrdenDetallePage } from './features/ordenes/OrdenDetallePage'
import { OrdenesPage } from './features/ordenes/OrdenesPage'
import { TareasFrecuentesPage } from './features/tareasFrecuentes/TareasFrecuentesPage'
import { UsuariosPage } from './features/usuarios/UsuariosPage'
import { CatalogoRepuestosPage } from './features/repuestos/CatalogoRepuestosPage'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          element={
            <RequireAuth>
              <Layout />
            </RequireAuth>
          }
        >
          <Route index element={<InicioPage />} />
          <Route path="ordenes" element={<OrdenesPage />} />
          <Route path="ordenes/:id" element={<OrdenDetallePage />} />
          <Route
            path="repuestos"
            element={
              <RequireAuth roles={['administrador']}>
                <CatalogoRepuestosPage />
              </RequireAuth>
            }
          />
          <Route
            path="clientes"
            element={
              <RequireAuth roles={['administrador']}>
                <ClientesPage />
              </RequireAuth>
            }
          />
          <Route
            path="usuarios"
            element={
              <RequireAuth roles={['administrador']}>
                <UsuariosPage />
              </RequireAuth>
            }
          />
          <Route
            path="tareas-frecuentes"
            element={
              <RequireAuth roles={['administrador']}>
                <TareasFrecuentesPage />
              </RequireAuth>
            }
          />
          <Route
            path="configuracion"
            element={
              <RequireAuth roles={['administrador']}>
                <ConfiguracionPage />
              </RequireAuth>
            }
          />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App
