# AGENTS.md

Instrucciones para agentes y contribuidores que trabajan en este repositorio.

## Producto

Software de gestión para un único taller mecánico. Reemplaza el cuaderno y WhatsApp que hoy usan para coordinar el trabajo del día.

El eje del sistema es la **orden de trabajo**: cuando entra un vehículo se abre una orden asociada al cliente. De esa orden se desprenden **tareas** que cualquier mecánico disponible puede tomar, marcar como terminadas o liberar.

Sobre la misma orden se cargan **repuestos comprados al vuelo** (sin inventario permanente), con costo real y un margen para calcular el precio al cliente. Al cerrar la orden el sistema calcula el total (mano de obra + repuestos) y registra un cobro único al final.

Roles: administrador (recepción y control de órdenes, repuestos y cobros) y mecánico (interfaz móvil para ver y tomar tareas).

No construir un ERP ni un sistema de stock. El diferencial es el modelo pull de tareas (cualquier mecánico toma trabajo disponible) y el registro simple de repuestos comprados al momento.

## Stack

- Backend: Ruby on Rails 8 (API only) + PostgreSQL
- Frontend: React como PWA responsive (web de recepción y vista móvil para mecánicos). Vive en `frontend/`.
- Tests: RSpec + FactoryBot
- Auth prevista: JWT con roles mecánico y administrador

Arquitectura: monolito modular cliente-servidor.

```
Usuario → React/PWA → API Ruby on Rails → PostgreSQL
```

La orden de trabajo es la entidad central. Agrupa cliente, vehículo, tareas, repuestos y el pago. Una tarea tiene mecánico responsable y estado. No introducir microservicios.

## Convenciones de código

- MVC de Rails + objetos de servicio en `app/services/` para la lógica de negocio (ej. `TareaTomar`, `TareaLiberar`, `OrdenCerrar`, `RepuestoAgregar`).
- Los controllers reciben el request y delegan. Los modelos ActiveRecord manejan persistencia, relaciones y validaciones de datos, no lógica de flujo.
- Tomar una tarea debe ser concurrente-seguro (`with_lock` o lock optimista con `lock_version`): una tarea tomada no puede ser tomada al mismo tiempo por otro mecánico.
- Tiempo real: Action Cable (Solid Cable) para notificar cambios de estado de tareas y órdenes.
- Estilo Ruby: RuboCop Rails Omakase (`bin/rubocop`).
- No escribir comentarios inline en el código salvo que el developer lo pida explícitamente.
- El backend (Rails API) vive en la raíz. El frontend React queda en `frontend/`; no mezclar código de uno en el árbol del otro.

## Commits y pull requests

Los **mensajes de commit** y el **título del pull request** deben seguir [Conventional Commits](https://www.conventionalcommits.org/).

Formato:

```
<type>(<scope>): <description>
```

Reglas:

- `type` obligatorio, en minúsculas, de la lista de abajo.
- `scope` opcional, en minúsculas (ej. `tareas`, `ordenes`, `repuestos`, `clientes`, `vehiculos`, `pagos`, `auth`, `ci`).
- Breaking change: `!` después del type o del scope, por ejemplo `feat(pagos)!: cambiar el cobro a múltiples pagos`.
- `description` en español, modo imperativo, sin punto final.
- La primera línea tiene como máximo 100 caracteres.

Tipos permitidos:

| Tipo | Uso |
| --- | --- |
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de un bug |
| `docs` | Solo documentación |
| `style` | Formato, sin cambio de comportamiento |
| `refactor` | Cambio de código sin feat ni fix |
| `perf` | Mejora de performance |
| `test` | Agregar o corregir tests |
| `build` | Dependencias, empaquetado, Docker |
| `ci` | Workflows y scripts de CI |
| `chore` | Mantenimiento que no entra en otro tipo |
| `revert` | Revertir un commit previo |

Ejemplos válidos:

- `feat(tareas): permitir tomar una tarea disponible`
- `fix(ordenes): impedir cerrar una orden sin pago`
- `docs: explicar el flujo de la orden de trabajo`
- `ci: validar conventional commits en pull requests`

Ejemplos inválidos: `Update`, `Fix bug`, `cambios en tareas`, `feat: agregar login.`.

El CI del pull request valida el título y cada commit (se ignoran commits de merge). Si no cumple, el check falla.

Para comprobarlo en local:

```
script/check-conventional-commits --title "feat(tareas): permitir tomar una tarea disponible"
script/check-conventional-commits --from origin/main --to HEAD
```

## Tests

```
bundle exec rspec
```

Antes de dar por terminado un cambio de backend, corre los tests afectados. Si tocaste Ruby, corre también `bin/rubocop`.
