# Frontend — Gestión de Taller

Aplicación React que consume la API de Rails del proyecto (carpeta `../` en la raíz del repo). Pensada como panel único usado tanto desde web (recepción/administración) como desde el celular (mecánicos), con vistas adaptadas según el rol.

Desde la raíz del repo, `docker compose up` levanta la base, la API y esta app. El detalle está en el [README de la raíz](../README.md).

## Stack

- [Vite](https://vitejs.dev/) + React + TypeScript
- [React Router](https://reactrouter.com/) para el ruteo
- [TanStack Query](https://tanstack.com/query) para pedir y cachear datos de la API
- Axios como cliente HTTP, con interceptor de autenticación (JWT)
- ESLint para linting

## Cómo levantarlo

No se levanta por separado. Desde la raíz del repo, `docker compose up` levanta la base, la API y esta app, y `docker compose down` baja todo. Compose instala las dependencias con pnpm y pasa `VITE_API_URL=http://localhost:3000`.

La app queda en `http://localhost:5173`. El ingreso es `http://localhost:5173/login`, con el email y la contraseña de `ADMIN_EMAIL` y `ADMIN_PASSWORD` del `.env` de la raíz.

Abrí esa URL con `localhost`. CORS del backend solo permite `http://localhost:5173`. Vite no cambia de puerto: si 5173 está ocupado, no arranca.

Los cambios en `src/` se recargan solos. Si cambia `package.json` o `pnpm-lock.yaml`, reiniciá el stack: el contenedor corre `pnpm install` al arrancar.

Para correr los scripts en el host hace falta Node.js `^20.19.0` o `>=22.12.0` (lo exige Vite 8) y pnpm (`corepack enable` si no lo tenés). El lockfile es `pnpm-lock.yaml`.

## Scripts

```
pnpm dev       # servidor de desarrollo
pnpm build     # build de producción
pnpm lint      # corre ESLint
pnpm preview   # sirve el build de producción localmente
```

## Convenciones

- Toda llamada a la API pasa por `src/lib/api.ts` (no instanciar Axios suelto en otros lados), para que el token JWT se adjunte siempre igual.
- Los datos remotos se manejan con TanStack Query (`useQuery`/`useMutation`), no con `useEffect` + `useState` a mano, para aprovechar el caché e invalidación cuando lleguen eventos en tiempo real (ActionCable) más adelante.
- Cada feature es lo más autocontenida posible: sus propios componentes, hooks y llamadas a la API viven dentro de su carpeta en `features/`.
