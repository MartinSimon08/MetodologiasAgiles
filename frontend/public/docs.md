# Documentación de la API de Gestión de Taller

Esta es la documentación pública de la API de Gestión de Taller. Sirve para saber cómo autenticarse y qué recursos existen. No reemplaza la sesión: casi todo pide un token de un usuario del taller.

## Dónde está

En el sitio publicado, la API vive en el mismo origen bajo `/api`. El chequeo de vida es `GET /api/up`. El catálogo de enlaces, en el formato de la RFC 9727, está en `/.well-known/api-catalog`.

## Sesión

`POST /api/sesion` recibe `email` y `password`. Si coinciden con un usuario activo, responde 201 y un JSON `{ "token": "..." }`. Si no, responde 401. El resto de las llamadas lleva `Authorization: Bearer` y ese token.

`GET /api/sesion` devuelve el usuario actual: `id`, `nombre`, `email` y `rol`. Una respuesta autenticada puede traer el header `X-Token-Renovado` con un token nuevo. Sin token válido, la respuesta es 401. Si el rol no alcanza para esa acción, la respuesta es 403.

## Roles

El administrador es la recepción. Abre, cierra y cancela órdenes. Carga clientes, vehículos, repuestos, usuarios y la configuración del taller. El mecánico toma, completa y libera tareas, y puede avisar un repuesto. No administra el taller.

## Recursos

Los recursos principales son `ordenes`, `tareas`, `repuestos`, `adelantos`, `clientes`, `vehiculos`, `casos`, `aseguradoras`, `usuarios`, `repuestos_catalogo` y `tareas_frecuentes`. Tomar una tarea es una sola escritura a la vez: dos mecánicos no pueden quedarse con la misma. Cerrar una orden calcula el total de mano de obra y repuestos.

## Qué no ofrece

No hay una clave de API distinta del usuario del taller, ni webhooks, ni un portal para terceros. El detalle de cada acción está en el [repositorio](https://github.com/MartinSimon08/MetodologiasAgiles), enlazado también desde [llms.txt](/llms.txt).

## Páginas

- [Inicio](/)
- [Acerca de](/about)
- [Contacto](/contact)
- [Privacidad](/privacy)
- [llms.txt](/llms.txt)
