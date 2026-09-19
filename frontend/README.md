# Frontend — Gestión de Taller

Aplicación React que consume la API de Rails del proyecto (carpeta `../` en la raíz del repo). Pensada como panel único usado tanto desde web (recepción/administración) como desde el celular (mecánicos), con vistas adaptadas según el rol.

## Stack

- [Vite](https://vitejs.dev/) + React + TypeScript
- [React Router](https://reactrouter.com/) para el ruteo
- [TanStack Query](https://tanstack.com/query) para pedir y cachear datos de la API
- Axios como cliente HTTP, con interceptor de autenticación (JWT)
- ESLint para linting

## Requisitos previos

- Node.js (versión que uses en el backend/monorepo, o la última LTS)
- pnpm (`corepack enable` si no lo tenés instalado)
- El backend corriendo en `http://localhost:3000` (ver README de la raíz del repo)

## Setup local

1. Parate en esta carpeta:
   ```
   cd frontend
   ```
2. Instalá las dependencias:
   ```
   pnpm install
   ```
3. Copiá `.env.example` a `.env` y ajustá si hace falta:
   ```
   VITE_API_URL=http://localhost:3000
   ```
4. Levantá el servidor de desarrollo:
   ```
   pnpm dev
   ```
   La app queda disponible en `http://localhost:5173`.

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