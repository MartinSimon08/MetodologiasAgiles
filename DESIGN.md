---
version: alpha
name: Gestión de Taller
description: Sistema visual del frontend React (recepción y vista móvil de mecánicos). Fuente de verdad del código en frontend/src/index.css.
colors:
  primary: "#181818"
  on-primary: "#fcfcf9"
  primary-hover: "#000000"
  background: "#efefe4"
  surface: "#fcfcf9"
  surface-note: "#f7f7f1"
  control: "#eaeae7"
  field: "#ffffff"
  outline: "#d7d7d6"
  text: "#181818"
  text-muted: "#909090"
  attention: "#ffcf3f"
  link: "#0071bb"
  error: "#8f2d2d"
  error-hover: "#731f1f"
  error-container: "#f8ecec"
typography:
  display:
    fontFamily: IBM Plex Sans
    fontSize: 64px
    fontWeight: 300
    lineHeight: 64px
    letterSpacing: -0.04em
  headline:
    fontFamily: IBM Plex Sans
    fontSize: 32px
    fontWeight: 300
    lineHeight: 36px
    letterSpacing: -0.03em
  amount:
    fontFamily: IBM Plex Sans
    fontSize: 28px
    fontWeight: 300
    lineHeight: 32px
    letterSpacing: -0.03em
    fontFeature: '"tnum"'
  title:
    fontFamily: IBM Plex Sans
    fontSize: 18px
    fontWeight: 500
    lineHeight: 28px
  body:
    fontFamily: IBM Plex Sans
    fontSize: 16px
    fontWeight: 400
    lineHeight: 24px
    fontFeature: '"tnum"'
  body-strong:
    fontFamily: IBM Plex Sans
    fontSize: 16px
    fontWeight: 500
    lineHeight: 24px
  label:
    fontFamily: IBM Plex Mono
    fontSize: 12px
    fontWeight: 500
    lineHeight: 16px
    letterSpacing: 0.08em
rounded:
  none: 0px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 20px
  2xl: 28px
  3xl: 48px
  touch-target: 44px
  sidebar: 232px
  content-max: 1440px
  grid: 120px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.none}"
    padding: 14px
    height: 44px
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
    textColor: "{colors.on-primary}"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.none}"
    padding: 14px
    height: 44px
  button-danger:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-primary}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.none}"
    height: 44px
  button-danger-hover:
    backgroundColor: "{colors.error-hover}"
    textColor: "{colors.on-primary}"
  input:
    backgroundColor: "{colors.field}"
    textColor: "{colors.text}"
    typography: "{typography.body}"
    rounded: "{rounded.none}"
    padding: 12px
    height: 44px
  form-label:
    textColor: "{colors.text-muted}"
    typography: "{typography.label}"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.none}"
    padding: 20px
  note:
    backgroundColor: "{colors.surface-note}"
    textColor: "{colors.text}"
    rounded: "{rounded.none}"
    padding: 12px
  badge:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    typography: "{typography.label}"
    rounded: "{rounded.none}"
    padding: 4px
  badge-active:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label}"
  badge-pending:
    backgroundColor: "{colors.attention}"
    textColor: "{colors.text}"
    typography: "{typography.label}"
  error-block:
    backgroundColor: "{colors.error-container}"
    textColor: "{colors.error}"
    rounded: "{rounded.none}"
    padding: 12px
  nav-item-active:
    backgroundColor: "{colors.control}"
    textColor: "{colors.text}"
    typography: "{typography.label}"
  link:
    textColor: "{colors.link}"
    typography: "{typography.body-strong}"
---

# Gestión de Taller

Este archivo sigue el formato [DESIGN.md](https://github.com/google-labs-code/design.md) de Google Labs. Los tokens del front matter son los valores exactos; el texto explica cómo y cuándo usarlos. La implementación vive en `frontend/src/index.css`: si cambia un valor ahí, se actualiza acá en el mismo PR.

## Overview

Herramienta de trabajo para un taller mecánico, no un producto de marketing. La estética es la de una planilla técnica o un cuaderno de taller ordenado: fondo papel con una grilla tenue, tinta casi negra, bordes finos, esquinas rectas y casi nada de color. El color se reserva para comunicar estado (pendiente, rechazado, peligro).

Dos contextos de uso:

- **Recepción (administrador)**: escritorio o tablet, listas densas, formularios y cierre de órdenes con totales.
- **Mecánicos**: celular en el taller, con manos ocupadas o sucias. Botones grandes, una columna, acciones al ancho completo.

Principios: legibilidad antes que decoración, números alineados (cifras tabulares), jerarquía por tipografía y bordes en lugar de sombras y colores.

## Colors

Paleta monocromática cálida con tres acentos funcionales. En CSS se exponen como variables en `:root` (entre paréntesis el nombre real).

- **primary** (`--tinta`): texto principal, botón primario, insignias activas, contorno de foco.
- **background** (`--papel`): fondo de página, con la grilla de 120px dibujada en `body::before`.
- **surface** (`--superficie`): tarjetas, listas, barra de navegación. También es el texto sobre fondo `primary`.
- **surface-note** (`--nota`): notas, avisos y resúmenes informativos.
- **control** (`--control`): estado activo de la navegación y hover de acciones de catálogo.
- **field** (`--blanco`): fondo de inputs, selects y textareas.
- **outline** (`--regla`): todos los bordes y separadores de 1px.
- **text-muted** (`--tinta-suave`): etiquetas, metadatos y texto secundario.
- **attention** (`--ambar`): estados que esperan acción (orden abierta, tarea pendiente, repuesto por valorizar) y advertencias.
- **link** (`--senal`): único azul del sistema, solo para enlaces de texto.
- **error** (`--peligro`) y **error-container** (`--peligro-fondo`): acciones destructivas, validación, órdenes canceladas y bloqueos de cierre.

Usar siempre las variables, nunca hex sueltos en componentes. Las únicas excepciones actuales son los hover (`#000000`, `#731f1f`), que están tokenizados acá como `primary-hover` y `error-hover`.

## Typography

Dos familias de IBM Plex, cargadas desde Google Fonts en `frontend/index.html`:

- **IBM Plex Sans** para todo el contenido. Pesos usados: 300 (títulos grandes y montos), 400 (texto), 500 (énfasis, botones, títulos de sección), 600 (leyendas de fieldset).
- **IBM Plex Mono** solo para etiquetas: `.kicker`, labels de formularios, insignias, ítems de navegación y encabezados de bloque. Siempre 12px, peso 500, en mayúsculas y con tracking positivo (0.04em a 0.08em).

Los títulos grandes van livianos (300) con tracking negativo; el énfasis se logra con tamaño, no con negrita. Todo el sistema usa cifras tabulares (`font-variant-numeric: tabular-nums`) para que los montos y cantidades queden alineados en columnas.

Escala: `display` solo en el login de escritorio, `headline` para el h1 de cada página y el total parcial de una orden, `amount` para saldos, `title` para h2, `body` para el resto.

## Layout

- **Móvil primero.** Breakpoints en uso: `600px` (acciones al ancho completo por debajo), `640px` (más padding lateral), `900px` (pasa a layout de escritorio).
- **Escritorio (≥900px)**: grilla de dos columnas, barra lateral fija de 232px a la izquierda y contenido a la derecha.
- **Móvil (<900px)**: la barra pasa arriba, sticky, y la navegación se abre en una columna desde el botón de menú.
- **Contenido**: ancho máximo 1440px centrado, padding 28px arriba y 16px (28px desde 640px) a los costados.
- Espaciado vertical entre bloques de 1rem a 1.25rem; dentro de formularios 0.9rem.
- Todo elemento interactivo mide al menos 44px de alto (`touch-target`).

## Elevation & Depth

El sistema es plano. La profundidad se expresa con bordes de 1px en `outline` y cambios de fondo (`background` → `surface` → `field`), no con sombras.

Excepciones permitidas:

- Notificaciones flotantes de tareas (`.aviso-tarea`): sombra mínima `0 2px 4px #00000020` y borde en `primary`.
- Indicadores de selección con sombra inset de 2px a 4px en `primary` (navegación activa: abajo en móvil, a la izquierda en escritorio).
- Diálogos (`.dialogo`) sobre un fondo velado (`.dialogo-fondo`).

## Shapes

Esquinas rectas en todo: `border-radius: 0` en botones, inputs, tarjetas, insignias, avisos y diálogos. Los bordes son de 1px; el único trazo más grueso es el contorno de foco (2px, offset 2px) y los indicadores inset de selección.

El ícono del select se dibuja con gradientes CSS. Los íconos SVG son de trazo (`stroke: currentColor`, ancho 1.6, extremos redondeados), sin relleno.

## Components

- **Botón primario**: fondo `primary`, texto `surface`, peso 500, 44px de alto. Hover a negro puro.
- **Botón secundario** (`.secundario`): transparente con borde `outline`; hover con velo negro al 5%.
- **Botón de peligro** (`.peligro`): fondo `error`. La variante `.secundario.peligro` es solo contorno y texto `error`, con hover en `error-container`.
- **Botón deshabilitado**: opacidad 0.5 y cursor `not-allowed`.
- **Inputs, selects y textareas**: fondo `field`, borde `outline`, 44px de alto, ancho completo. Inválido: borde y texto en `error`, y el label también se pone en `error`.
- **Label de formulario**: Plex Mono 12px en mayúsculas, color `text-muted`, arriba del campo. Las ayudas (`small`, `.bajada`) vuelven a Plex Sans 16px.
- **Tarjeta** (`.tarjeta`): fondo `surface`, borde `outline`, padding 1.25rem.
- **Lista** (`.lista`): un solo contenedor con borde; las tarjetas internas pierden el borde propio y se separan con una línea inferior.
- **Tabla** (`Tabla`, `.tabla` dentro de `.tabla-contenedor`): la forma de mostrar las pantallas de índice (órdenes, clientes, vehículos, usuarios, aseguradoras, casos, catálogos y reportes con filas). Contenedor en `surface` con borde `outline` y scroll horizontal si no entra. Encabezados en Plex Mono 12px mayúsculas `text-muted`; celdas separadas por línea `outline`; hover de fila en `surface-note`. Montos y cantidades en columnas `.numero` alineadas a la derecha; fechas en `.fecha` sin cortar línea; datos secundarios de una celda en `.secundaria` (`text-muted`) y ausencias como "—" en `.sin-dato`. Filas inactivas (`tr.inactiva`) en `text-muted`. Totales en `tfoot` con línea superior en `primary`, 16px peso 500. Las vistas para mecánicos y los paneles dentro de una orden siguen como `.lista` de tarjetas.
- **Paginación** (`Paginacion`, `.paginacion`): debajo de cada tabla de índice, siempre que haya filas. A la izquierda el selector "Mostrar 10/15/20/25 por página" (10 por defecto; la elección se recuerda en el navegador y vale para todas las pantallas), al centro el rango "1–10 de 37" con la página actual en `text-muted`, y a la derecha Anterior/Siguiente como botones secundarios cuando hay más de una página. Cambiar la cantidad vuelve a la primera página. Toda pantalla de índice lleva además un buscador (`Buscador`) arriba de la tabla.
- **Menú de acciones** (`MenuAcciones`): botón "…" de 44px en la última columna (`.acciones-celda`) que abre una lista flotante con borde `primary`; ítems de 44px con hover en `control`, y los destructivos en `error` con hover en `error-container`. Se maneja con flechas y Escape. Las acciones que necesitan datos (editar, cambiar dueño, turno, resetear contraseña) abren un `Dialogo` en lugar de un formulario dentro de la fila.
- **Estado vacío** (`EstadoVacio`): bloque centrado en `surface` con borde, ícono de trazo, título 16px peso 500 y descripción en `text-muted`. La variante de búsqueda (ícono de lupa) se usa cuando hay filtros sin resultados.
- **Encabezado de página** (`.encabezado`): título a la izquierda, acción a la derecha, línea inferior en `outline`.
- **Insignia de estado** (`.insignia-<estado>`): Plex Mono en mayúsculas con borde. Variantes:
  - en curso, ingresado: fondo `primary`.
  - abierta, pendiente, pendiente de valorizar, listo para retirar: fondo `attention`.
  - cerrada, terminada, valorizado, desactivado: texto `text-muted`.
  - aprobada: borde `primary`.
  - cancelada, rechazada, supera el cupo: texto y borde `error`.
  - turno asignado: insignia base, sin color.
- **Turnera** (`.dias-turnera`): un bloque por día con encabezado (día, ingresos contra cupo) y una `.lista` de turnos. El día de hoy lleva la línea inferior en `primary`; un día que supera el cupo la lleva en `error`, con el conteo en `error` y la insignia "Supera el cupo".
- **Calendario de la turnera** (`.calendario-turnera`): grilla de 7 columnas (lunes a domingo) en `surface` con líneas `outline`. Cada día es un enlace a su semana con el número, ingresos contra cupo (en `error` si se supera) y hasta tres patentes en Plex Mono 12px: turno asignado con borde `outline`, ingresado en `primary` y listo para retirar en `attention`. Los días de otro mes van sobre `background` con texto `text-muted`; hoy lleva el número invertido y línea superior en `primary`, y un día excedido la lleva en `error`. Por debajo de 600px se ocultan las patentes y queda solo el conteo.
- **Tablero de órdenes** (`.tablero-ordenes`): una columna por estado con encabezado (insignia del estado y cantidad) y una `.lista` de tarjetas. Tres columnas desde 900px, apiladas por debajo. Se alterna con la lista mediante `.subnav`. Al arrastrar una orden abierta, las columnas que la aceptan toman fondo `control` con borde inset de 1px en `primary` (2px cuando la orden está encima) y el resto baja a opacidad 0.6.
- **Avisos**: `.aviso` en `surface-note` para información; `.advertencia` en `attention` para algo que requiere atención; `.bloqueo-cierre` y `.orden-cancelada` en `error-container` con borde `error`.
- **Totales** (`.totales-cierre`): filas etiqueta/monto separadas por líneas, borde superior en `primary` y total final a 18px peso 500.
- **Navegación activa**: fondo `control` con indicador inset en `primary`.
- **Enlaces de texto**: color `link`, peso 500, subrayado con offset de 3px.
- **Vista móvil de tareas** (`.tarea-movil`): una columna; por debajo de 600px los botones de acción ocupan el ancho completo.

## Do's and Don'ts

**Hacer**

- Reusar las clases y variables de `index.css` antes de crear estilos nuevos.
- Reservar el color para estados. Si algo no comunica estado, va en `primary`, `text-muted` u `outline`.
- Mantener 44px mínimos en todo lo tocable, sobre todo en la vista de mecánicos.
- Mostrar montos con cifras tabulares y alineados a la derecha.
- Mantener visible el contorno de foco (`:focus-visible`) y respetar `prefers-reduced-motion`.
- Actualizar este archivo en el mismo PR cuando cambie un token.

**Evitar**

- Esquinas redondeadas, sombras decorativas, gradientes o fondos de color en tarjetas.
- Nuevos colores de marca o un segundo color de acento.
- Negritas para jerarquía en títulos grandes: usar tamaño y peso 300.
- Plex Mono para texto corrido; es solo para etiquetas cortas en mayúsculas.
- Usar `text-muted` para texto importante: sobre `background` tiene bajo contraste (no llega a WCAG AA para texto normal). Sirve para etiquetas y metadatos, no para información crítica.
- Usar el azul `link` en botones o fondos.
