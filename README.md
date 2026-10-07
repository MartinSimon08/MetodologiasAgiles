![Gestión de Taller: del ingreso del vehículo al cobro](docs/images/portada.png)

# Gestión de Taller

Software de gestión para un taller mecánico único, pensado para el dinamismo real de un taller: los mecánicos atienden vehículos según disponibilidad (no hay asignación fija), y los repuestos se compran al vuelo sin stock permanente, cargándose a la orden con su costo real.

El backend es una API Ruby on Rails (modo `--api`). El frontend React vive en `frontend/` y es la pantalla de recepción y la vista móvil de los mecánicos. En local hay que levantar los dos procesos. La guía del frontend está en [`frontend/README.md`](frontend/README.md).

## Stack

- Ruby 4.0.7 (`.ruby-version`, pensado para rbenv)
- Rails 8.1 (modo API)
- PostgreSQL 16, solo la base, vía Docker Compose
- Frontend: Vite, React y TypeScript en `frontend/` (pnpm)
- RSpec + FactoryBot
- Autenticación por JWT (roles: mecánico / administrador)

## Requisitos previos

- Ruby 4.0.7. Dentro del repo, `rbenv install` lee `.ruby-version`.
- Bundler 4.0.21, la versión con la que se generó `Gemfile.lock`:
  ```
  gem install bundler -v 4.0.21
  ```
- Docker y Docker Compose.
- Librerías para compilar las gemas nativas y usar `ruby-vips` en runtime. En Debian/Ubuntu:
  ```
  sudo apt-get install -y build-essential git libpq-dev libyaml-dev libvips pkg-config
  ```
- Para el frontend: Node.js `^20.19.0` o `>=22.12.0` (lo exige Vite 8) y pnpm (`corepack enable` si no lo tenés).

El contenedor publica Postgres en el puerto 5432 del host. Ese puerto tiene que estar libre.

## Variables de entorno

Copiá `.env.example` a `.env` en la raíz. Docker Compose lee ese archivo al crear el contenedor. Rails lo carga en development y test con `dotenv-rails`.

Completá `DB_USER`, `DB_PASSWORD` y `DB_NAME`. Con alguna vacía, el contenedor de Postgres no arranca.

- `DB_USER` y `DB_PASSWORD`: usuario con el que Rails se conecta.
- `DB_NAME`: base inicial que crea la imagen de Postgres la primera vez.
- La app usa otras dos bases, fijas en `config/database.yml`: `metodologias_agiles_development` y `metodologias_agiles_test`. El usuario de `DB_USER` tiene que poder crearlas. En la imagen oficial, ese usuario es superusuario.
- `ADMIN_EMAIL` y `ADMIN_PASSWORD`: identifican al administrador que crea el seed. Sin las dos, el seed no crea ningún usuario.
- `ADMIN_NOMBRE`: nombre de ese administrador. Si falta, el seed usa `Administrador`.

## Setup local

1. Cloná el repo y parate en la raíz.
2. Copiá y completá `.env`, como está arriba.
3. Levantá Postgres:
   ```
   docker compose up -d
   ```
4. Instalá las gemas:
   ```
   bundle install
   ```
5. Creá y migrá la base de development:
   ```
   bin/rails db:create
   bin/rails db:migrate
   ```
6. Creá el administrador:
   ```
   bin/rails db:seed
   ```
   Hace falta `ADMIN_EMAIL` y `ADMIN_PASSWORD` en `.env`. El seed crea ese administrador. Otros usuarios, incluido un mecánico, se dan de alta después desde la pantalla Usuarios.
7. Levantá la API:
   ```
   bin/rails server
   ```
8. En otra terminal, levantá el frontend:
   ```
   cd frontend
   pnpm install
   cp .env.example .env
   pnpm dev
   ```

`bin/setup` instala gemas, prepara la base de development y arranca la API. Para dejar el proyecto usable seguí también los pasos de `.env`, Docker y frontend. `bin/dev` solo arranca la API. Los comandos de Rails van con `bin/rails`.

## Cómo acceder

La API y el frontend tienen que estar corriendo a la vez.

- Interfaz: <http://localhost:5173/login>
- API: <http://localhost:3000>
- Chequeo de que la API responde: `GET http://localhost:3000/up`

Entrá con el email y la contraseña de `ADMIN_EMAIL` y `ADMIN_PASSWORD`.

Abrí el frontend en `http://localhost:5173`. CORS solo permite ese origen: `http://127.0.0.1:5173` no pasa, y si el puerto 5173 está ocupado Vite elige otro y el navegador no puede llamar a la API.

## Tests

Prepará la base de test y corré la suite desde la raíz:

```
bin/rails db:test:prepare
bundle exec rspec
```

## Convenciones del proyecto

- **Arquitectura**: MVC estándar de Rails + objetos de servicio para la lógica de negocio (`app/services/`). Los controllers reciben el request y delegan. Los modelos ActiveRecord manejan persistencia, relaciones y validaciones de datos.
  - Ejemplos de servicios: `TareaTomar`, `TareaLiberar`, `OrdenAbrir`, `RepuestoAgregar`.
- **Concurrencia de tareas**: tomar una tarea usa lock optimista (`lock_version`) o `with_lock` explícito, para evitar que dos mecánicos tomen la misma tarea al mismo tiempo.
- **Tiempo real**: Action Cable (Solid Cable) queda para avisar cambios de tareas y órdenes. En development el adapter es `async`. El cliente de Action Cable en el frontend queda pendiente.
