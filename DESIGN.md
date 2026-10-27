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
  content-max: 1080px
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
- **Móvil (<900px)**: la barra pasa arriba, sticky, con la navegación en una fila horizontal que hace wrap.
- **Contenido**: ancho máximo 1080px centrado, padding 28px arriba y 16px (28px desde 640px) a los costados.
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
- **Encabezado de página** (`.encabezado`): título a la izquierda, acción a la derecha, línea inferior en `outline`.
- **Insignia de estado** (`.insignia-<estado>`): Plex Mono en mayúsculas con borde. Variantes:
  - en curso: fondo `primary`.
  - abierta, pendiente, pendiente de valorizar: fondo `attention`.
  - cerrada, terminada, valorizado, desactivado: texto `text-muted`.
  - aprobada: borde `primary`.
  - cancelada, rechazada: texto y borde `error`.
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
