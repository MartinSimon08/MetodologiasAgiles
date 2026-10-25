# Cómo contribuir

Gestión de Taller es el software de un único taller mecánico. El producto, el flujo de una orden y el setup local están en el [README](README.md). Acá está cómo proponer un cambio.

## Antes de escribir código

- El eje es la orden de trabajo. No sumes sucursales, stock permanente ni un ERP.
- La lógica de flujo va en `app/services/`. Los controllers reciben el request y delegan. Los modelos persisten y validan datos.
- El backend es la API Rails de la raíz. El frontend React queda en `frontend/`.
- Tomar una tarea tiene que ser concurrente-seguro (`with_lock` o `lock_version`): dos mecánicos no pueden tomar la misma tarea a la vez.
- No dejes comentarios inline salvo que el cambio lo pida.
- El contrato para quien mantiene el repo está en [AGENTS.md](AGENTS.md).

## Entorno

Seguí el [setup del README](README.md#setup-local): copiá `.env.example` a `.env`, completalo y levantá el stack con `docker compose up --build`.

La interfaz queda en <http://localhost:5173/login>. CORS solo acepta ese origen.

## Tests y lint

Con el stack levantado:

```
docker compose exec -e RAILS_ENV=test api sh -c "bin/rails db:test:prepare && bundle exec rspec"
docker compose exec api bin/rubocop
docker compose exec frontend pnpm lint
docker compose exec frontend pnpm exec tsc -b --pretty false
```

Si tocaste Ruby, corré los specs del cambio y RuboCop. Si tocaste el frontend, corré el lint y `tsc`. Un cambio que solo toca documentación no necesita la suite.

La suite del proyecto es RSpec. El job `test` del CI corre `bin/rails test` y no ejecuta esos specs.

## Ramas y commits

1. Actualizá `main` y creá la rama desde ahí.
2. `main` está protegida. El cambio entra por pull request hacia `main`.
3. El título del pull request y cada commit siguen [Conventional Commits](https://www.conventionalcommits.org/).

Formato:

```
tipo(scope): descripción
```

- `tipo` obligatorio, en minúsculas: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- `scope` opcional, en minúsculas (por ejemplo `tareas`, `ordenes`, `repuestos`, `auth`, `ci`).
- Descripción en español, modo imperativo, sin punto final.
- La primera línea tiene como máximo 100 caracteres.
- Un breaking change lleva `!` después del tipo o del scope, por ejemplo `feat(pagos)!: cambiar el cobro a múltiples pagos`.

Ejemplos válidos:

- `feat(tareas): permitir tomar una tarea disponible`
- `docs: explicar el flujo de la orden de trabajo`

Ejemplos que el CI rechaza: `Update`, `Fix bug`, `cambios en tareas`, `feat: agregar login.`.

Para comprobarlo en local:

```
script/check-conventional-commits --title "feat(tareas): permitir tomar una tarea disponible"
script/check-conventional-commits --from origin/main --to HEAD
```

El CI valida el título y cada commit. Ignora los commits de merge.

## Pull request

Usá [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md).

- Si el PR completa un ticket importado desde Trello, escribí `Closes #123` en una línea independiente, con el número real del issue. No inventes números.
- Si el PR es parcial, escribí `Relacionado con #123` y qué falta. `Closes` queda para el PR final.
- Si no hay ticket, escribí `No aplica` y el motivo. No crees un ticket solo para llenar la plantilla.
- La referencia va fuera de comentarios HTML y de bloques de código. Varios tickets: una línea por issue.
- Conservá el marcador `<!-- trello-card:ID -->` de los issues importados.

Un PR listo con `Closes` mueve la tarjeta a `En Revisión / Esperando Merge`. Al integrarse en `main`, la tarjeta pasa a `Hecho`. Un PR parcial no mueve la tarjeta. El detalle está en [docs/trello-github.md](docs/trello-github.md).

GitHub pide review a quienes figuran en [`.github/CODEOWNERS`](.github/CODEOWNERS). Si `main` exige aprobación de un code owner, alcanza con uno de esos usuarios.

## Licencia

Al contribuir, aceptás que tu cambio quede bajo la licencia [MIT](LICENSE).
