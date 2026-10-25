# Deploy a producción

Cada push a `main` dispara el workflow `CI`. Si termina bien, el workflow `Deploy` (`.github/workflows/deploy.yml`) corre `bin/kamal deploy` y publica la versión nueva sin cortar el servicio. También se puede lanzar a mano desde Actions con **Run workflow**.

## Infraestructura

- VM `taller-app` en Oracle Cloud, región Brazil Southeast (Vinhedo), forma `VM.Standard.E2.1.Micro` (Always Free: 1 GB de RAM y 2 GB de swap).
- IP pública `204.216.155.6`. Es efímera: se mantiene al reiniciar o apagar la VM, pero cambia si se elimina la instancia.
- Puertos abiertos: 22, 80 y 443, en la Security List de `taller-vcn` y en el `iptables` de la VM.
- URL: `https://204-216-155-6.sslip.io`. sslip.io resuelve ese nombre a la IP y kamal-proxy saca el certificado de Let's Encrypt. Si cambia la IP, hay que actualizar `servers`, `proxy.host` y `accessories.db.host` en `config/deploy.yml`, y `DEPLOY_HOST` y `DEPLOY_HOST_KEY` en el workflow (`ssh-keyscan -t ed25519 <ip>`).

## Cómo queda armado

- Un solo contenedor sirve todo: el frontend compilado en `/` y la API en `/api`. El `Dockerfile` compila `frontend/` con `VITE_API_URL=/api` y `config.ru` monta Rails bajo `/api` cuando existe `FRONTEND_DIST_PATH`. En desarrollo no cambia nada.
- Postgres 16 corre como accessory de Kamal (`metodologias_agiles-db`), sin puerto publicado, con memoria ajustada para 1 GB. Los datos quedan en `/home/ubuntu/metodologias_agiles-db/data` de la VM.
- La imagen se construye en el runner de GitHub y viaja a la VM por SSH (registry local de Kamal), así que no hace falta un registry externo ni compilar en la VM.
- Rails tarda unos 40 segundos en arrancar en esta VM. Por eso `deploy_timeout` está en 120: Kamal espera ese tiempo a que `/api/up` responda antes de dar por caído el contenedor nuevo. Mientras tanto sigue sirviendo la versión anterior.
- Solid Queue no corre en producción porque la app no tiene jobs. Si se agregan, sumar `SOLID_QUEUE_IN_PUMA: true` en `env.clear` y medir la memoria.

## Secrets de GitHub Actions

Los crea el dueño del repo (o alguien con permiso de admin) en **Settings > Secrets and variables > Actions**:

| Secret | Contenido |
| --- | --- |
| `DEPLOY_SSH_KEY` | Clave privada SSH del usuario `ubuntu` de la VM, exclusiva para el deploy |
| `SECRET_KEY_BASE` | Firma de los JWT. Si cambia, se invalidan las sesiones abiertas |
| `POSTGRES_PASSWORD` | Contraseña de Postgres. Se usa al crear la base; cambiarla después requiere cambiarla también dentro de Postgres |

## Comandos útiles

Kamal necesita los secrets como variables de entorno (`SECRET_KEY_BASE` y `POSTGRES_PASSWORD`) y la clave SSH cargada en el agente:

```
bin/kamal app logs -f
bin/kamal console
bin/kamal accessory logs db
```

Crear el primer administrador (el seed solo crea el usuario si recibe las dos variables):

```
bin/kamal app exec "bin/rails db:seed" --env ADMIN_EMAIL:admin@taller.com ADMIN_PASSWORD:una-contraseña-segura
```

El primer deploy en una VM nueva se hace con `bin/kamal setup`, que levanta Postgres y kamal-proxy. Los siguientes los hace el workflow.
