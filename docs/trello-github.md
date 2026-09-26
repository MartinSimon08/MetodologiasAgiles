# Trello y GitHub

La importación se ejecuta manualmente desde GitHub Actions. Butler y un servidor propio no son necesarios.

Tablero: https://trello.com/b/S2Asw6vB/2026-utn-grupo10

| Evento | Resultado |
| --- | --- |
| Importación manual | Crea issues para tarjetas nuevas de `Sprint Backlog`. |
| PR abierto, reabierto o listo para revisión | Mueve la tarjeta a `En Revisión / Esperando Merge`. |
| PR integrado en `main` | Mueve la tarjeta a `Hecho`. |
| PR cerrado sin integrar | Conserva la lista actual. |

## 1. Guardar las credenciales

1. Entrá a [Trello Apps](https://trello.com/apps/admin) con una cuenta que pueda editar el tablero.
2. Creá una aplicación para esta integración, o seleccioná una existente.
3. En `Trello Auth`, generá una API key.
4. Generá un token con permisos `read,write` mediante la URL siguiente.
5. Reemplazá `TU_API_KEY` por la key generada antes de abrir la URL.

```text
https://trello.com/1/authorize?expiration=30days&scope=read,write&response_type=token&name=GitHub-Trello&key=TU_API_KEY
```

El token concede acceso a los tableros de esa cuenta. Vence a los 30 días y requiere renovación.

6. Abrí [Actions secrets del repositorio](https://github.com/MartinSimon08/MetodologiasAgiles/settings/secrets/actions).
7. Creá el secret `TRELLO_API_KEY` con la API key.
8. Creá el secret `TRELLO_TOKEN` con el token autorizado.

Guardá las credenciales solamente como secrets. No las pegues en issues, tarjetas ni archivos del repositorio.

GitHub proporciona `GITHUB_TOKEN` automáticamente. Esta integración no necesita un token personal de GitHub.

Referencia: [autorización de Trello](https://developer.atlassian.com/cloud/trello/guides/rest-api/authorization/).

## 2. Publicar los workflows

1. Integrá el PR de esta configuración en `main`.
2. Comprobá que GitHub Actions esté habilitado para el repositorio.

El botón de ejecución manual aparece cuando el workflow existe en la rama predeterminada.

## 3. Importar Sprint Backlog

1. Abrí `Actions → Importar Sprint Backlog → Run workflow`.
2. Seleccioná `main`.
3. Dejá activada `Solo vista previa`.
4. Ejecutá el workflow.
5. Comprobá la lista de cambios en el resumen de la ejecución.
6. Para crear los issues, repetí la ejecución con `Solo vista previa` desactivada.

Cada ejecución consulta las tarjetas actuales. La vista previa no congela una selección para la ejecución siguiente.

El job copia el título y la descripción. Agrega el enlace de Trello al issue y adjunta el issue a la tarjeta.
No copia comentarios, adjuntos, checklists, responsables ni etiquetas.

El job conserva el título, la descripción y el estado de los issues existentes.
Los cambios posteriores de Trello no sobrescriben esos issues.
Las tarjetas archivadas, las plantillas y las tarjetas de otras listas quedan excluidas.

El marcador `<!-- trello-card:ID -->` mantiene la relación. No lo elimines del issue.
El job consulta issues abiertos y cerrados antes de crear nuevos.
Si falla después de crear un issue, una nueva ejecución puede reparar el enlace sin duplicarlo.
Los reintentos de importación se ejecutan de uno en uno.

## 4. Asociar un PR

Agregá una línea independiente en la descripción del PR:

```text
Closes #123
```

Reemplazá `123` por el número del issue importado. Una mención aislada como `#123` no activa la integración.
Para varios issues, usá una línea `Closes` por issue.
También se admiten `Fixes` y `Resolves`.

El PR debe pertenecer al mismo repositorio, apuntar a `main` y tener un autor colaborador.
Los PRs de forks y los borradores quedan excluidos.
Al editar la descripción, el workflow vuelve a consultar las referencias.
Eliminar una referencia no revierte movimientos anteriores.
Un PR abierto no devuelve una tarjeta de `Hecho` a revisión.

La relación supone un PR final por ticket. Para tareas con varios PRs, usá `Closes` solamente en el PR final.
GitHub cierra el issue al integrar ese PR en la rama predeterminada.
La automatización mueve la tarjeta cuando GitHub informa el merge, sin esperar un despliegue.

## Fallos y pruebas

Si falta un secret, la ejecución falla e indica su nombre.
Si cambian los nombres de las listas, actualizá `lists` en `script/trello-sync.mjs`.
Si Trello devuelve `401`, renová las credenciales.
Si el workflow falla, comprobá el resumen y los logs antes de repetir la ejecución.

El workflow de PR usa `pull_request_target` y descarga solamente el commit base.
No ejecuta código del PR con las credenciales de Trello.

Pruebas locales sin credenciales ni escrituras externas:

```sh
node --test script/trello-sync.test.mjs
```

La prueba real requiere importar una tarjeta y abrir un PR asociado.
Antes de integrar ese PR, comprobá que la tarjeta esté en revisión.
Después del merge, comprobá que esté en `Hecho`.
