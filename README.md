![Gestión de Taller: del ingreso del vehículo al cobro](docs/images/portada.png)

# Gestión de Taller

Software de gestión para un taller mecánico único, pensado para el dinamismo real de un taller: los mecánicos atienden vehículos según disponibilidad (no hay asignación fija), y los repuestos se compran al vuelo sin stock permanente, cargándose a la orden con su costo real.

Backend API en Ruby on Rails (modo `--api`), consumido por un frontend en React (web + vista adaptada a mobile para los mecánicos).

## Stack

- Ruby 3.3.x (gestionado con rbenv, ver `.ruby-version`)
- Rails (modo API)
- PostgreSQL 16 (vía Docker)
- RSpec + FactoryBot para testing
- Autenticación por JWT (roles: mecánico / administrador)

## Requisitos previos

- Ruby instalado vía rbenv (`rbenv install` toma la versión de `.ruby-version` automáticamente)
- Docker y Docker Compose
- Bundler (`gem install bundler` si no lo tenés)

## Setup local

1. Cloná el repo y parate en la carpeta del proyecto.
2. Copiá `.env.example` a `.env` y completá las variables (usuario/password de la base local).
3. Levantá la base de datos:
   ```
   docker compose up -d
   ```
4. Instalá las dependencias:
   ```
   bundle install
   ```
5. Creá las bases de datos:
   ```
   rails db:create
   rails db:migrate
   ```
6. (Opcional) Cargá datos de ejemplo:
   ```
   rails db:seed
   ```
7. Levantá el servidor:
   ```
   rails server
   ```
   La API queda disponible en `http://localhost:3000`.

## Tests

```
bundle exec rspec
```

## Convenciones del proyecto

- **Arquitectura**: MVC estándar de Rails + objetos de servicio para la lógica de negocio (`app/services/`). Los controllers reciben el request y delegan; los modelos ActiveRecord manejan solo persistencia, relaciones y validaciones de datos — no lógica de flujo.
  - Ejemplos de servicios: `TareaTomar`, `TareaLiberar`, `OrdenCerrar`, `RepuestoAgregar`.
- **Concurrencia de tareas**: tomar una tarea usa lock optimista (`lock_version`) o `with_lock` explícito, para evitar que dos mecánicos tomen la misma tarea al mismo tiempo.
- **Tiempo real**: ActionCable (Solid Cable) para notificar cambios de estado de tareas/órdenes sin depender de polling desde el frontend.