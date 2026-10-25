# Política de seguridad

## Versiones

No hay releases numerados. La única rama que se mantiene es `main`. Un arreglo de seguridad entra ahí, por pull request. Las demás ramas no reciben ese parche por separado.

| Rama | Mantenida |
| --- | --- |
| `main` | sí |
| las demás | no |

## Reportar una vulnerabilidad

No abras un issue, un pull request ni una tarjeta de Trello. Esos canales son públicos.

El reporte privado de GitHub (Security Advisories) está desactivado en este repositorio. Hasta que se habilite, escribinos en privado al administrador del repositorio:

- Martin Simon: [martinforlini08@gmail.com](mailto:martinforlini08@gmail.com) o [@MartinSimon08](https://github.com/MartinSimon08)

Incluí qué falla, qué impacto tiene y cómo reproducirlo, con el commit o la rama. Si ya hay un secreto en el historial, decilo: `.env`, `config/master.key`, token de Trello o una contraseña.

Un bug sin impacto de seguridad sigue [CONTRIBUTING.md](CONTRIBUTING.md).

El grupo lo mira cuando puede. Si se filtró un secreto, hay que rotarlo y sacarlo del historial. Borrar el archivo en un commit posterior no alcanza: GitGuardian revisa cada commit del pull request.

## Qué no va en el repositorio

`.gitignore` deja afuera `.env` y `config/*.key`. Sí se commitea `.env.example`, con los valores vacíos.

No pegues en issues, commits, pull requests ni tarjetas:

- `DB_PASSWORD` ni `ADMIN_PASSWORD`
- `RAILS_MASTER_KEY` ni `config/master.key`
- `TRELLO_API_KEY` ni `TRELLO_TOKEN`
- tokens JWT ni contraseñas de usuarios

Esos valores viven en el `.env` local o en los [secrets de GitHub Actions](https://github.com/MartinSimon08/MetodologiasAgiles/settings/secrets/actions).

## Qué ya se controla

En cada pull request y en cada push a `main`:

- Brakeman revisa la API Rails. Es el job `scan_ruby` de [`.github/workflows/ci.yml`](.github/workflows/ci.yml).
- `bundler-audit` revisa gemas con vulnerabilidades conocidas, en el mismo job.
- GitGuardian marca secretos en los commits del pull request.
- Dependabot abre pull requests semanales para Bundler y para GitHub Actions (`.github/dependabot.yml`).
