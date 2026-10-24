![Gestión de Taller: del ingreso del vehículo al cobro](docs/images/portada.png)

# Gestión de Taller

Software de gestión para un taller mecánico único, pensado para el dinamismo real de un taller: los mecánicos atienden vehículos según disponibilidad (no hay asignación fija), y los repuestos se compran al vuelo sin stock permanente, cargándose a la orden con su costo real.

El backend es una API Ruby on Rails (modo `--api`). El frontend React vive en `frontend/` y es la pantalla de recepción y la vista móvil de los mecánicos. En local, `docker compose up` levanta la base, la API y el frontend. La guía del frontend está en [`frontend/README.md`](frontend/README.md).

## Stack

- Ruby 4.0.7 (`.ruby-version`, pensado para rbenv)
- Rails 8.1 (modo API)
- PostgreSQL 16, la API y el frontend, vía Docker Compose
- Frontend: Vite, React y TypeScript en `frontend/` (pnpm)
- RSpec + FactoryBot
- Autenticación por JWT (roles: mecánico / administrador)

## Requisitos previos

- Ruby 4.0.7. Dentro del repo, `rbenv install` lee `.ruby-version`.
- Bundler 4.0.21, la versión con la que se generó `Gemfile.lock`:
  ```
  gem install bundler -v 4.0.21
  ```
- Docker y Docker Compose. Con eso alcanza para levantar la app y correr los tests.
- Para correr RuboCop o el lint del frontend en el host: las librerías nativas y Node.js con pnpm. Node tiene que ser `^20.19.0` o `>=22.12.0`, que es lo que exige Vite 8. En Debian/Ubuntu:
  ```
  sudo apt-get install -y build-essential git libpq-dev libyaml-dev libvips pkg-config
  ```

Compose publica la base en el puerto 5432, la API en el 3000 y el frontend en el 5173. Esos tres puertos tienen que estar libres.

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
3. Levantá todo:
   ```
   docker compose up --build
   ```

Un solo comando levanta la base, la API y el frontend, en ese orden: la API espera a que Postgres esté listo y el frontend espera a la API. La primera vez construye las imágenes, instala gemas y dependencias del frontend, migra la base y corre el seed. Después alcanza con `docker compose up`. Para dejarlo en segundo plano: `docker compose up -d --wait`, que vuelve cuando los tres servicios responden.

Para bajar todo:

```
docker compose down
```

Baja y elimina los tres contenedores juntos. Los datos de la base quedan en el volumen `pgdata`. Para empezar de cero, con la base vacía: `docker compose down -v`.

El stack se llama siempre `metodologiasagiles`, sin importar el nombre de la carpeta. Un `docker compose down` desde cualquier worktree baja el mismo stack.

El contenedor de la API corre como el usuario `1000`. Si el tuyo es otro (`id -u`), agregá `HOST_UID` y `HOST_GID` en `.env`.

Hace falta `ADMIN_EMAIL` y `ADMIN_PASSWORD` en `.env` para que el seed cree el administrador. Otros usuarios, incluido un mecánico, se dan de alta después desde la pantalla Usuarios.

Los comandos de Rails corren dentro del contenedor de la API, por ejemplo `docker compose exec api bin/rails console`.

## Cómo acceder

- Interfaz: <http://localhost:5173/login>
- API: <http://localhost:3000>
- Chequeo de que la API responde: `GET http://localhost:3000/up`

Entrá con el email y la contraseña de `ADMIN_EMAIL` y `ADMIN_PASSWORD`.

Abrí el frontend en `http://localhost:5173`. CORS solo permite ese origen: `http://127.0.0.1:5173` no pasa. Vite usa el puerto 5173 y no lo cambia: si está ocupado, el frontend no arranca.

## Tests

Con el stack levantado, prepará la base de test y corré la suite dentro del contenedor de la API:

```
docker compose exec -e RAILS_ENV=test api sh -c "bin/rails db:test:prepare && bundle exec rspec"
```

## Deploy

Cada merge a `main` que pasa el CI se despliega solo con Kamal a una VM gratuita de Oracle Cloud. La app queda en `https://204-216-155-6.sslip.io`. Detalles, secrets y comandos: [Deploy a producción](docs/deploy.md).

## Convenciones del proyecto

- **Arquitectura**: MVC estándar de Rails + objetos de servicio para la lógica de negocio (`app/services/`). Los controllers reciben el request y delegan. Los modelos ActiveRecord manejan persistencia, relaciones y validaciones de datos.
  - Ejemplos de servicios: `TareaTomar`, `TareaLiberar`, `OrdenAbrir`, `RepuestoAgregar`.
- **Concurrencia de tareas**: tomar una tarea usa lock optimista (`lock_version`) o `with_lock` explícito, para evitar que dos mecánicos tomen la misma tarea al mismo tiempo.
- **Tiempo real**: Action Cable (Solid Cable) queda para avisar cambios de tareas y órdenes. En development el adapter es `async`. El cliente de Action Cable en el frontend queda pendiente.
