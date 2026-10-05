# Catálogo de repuestos (HU18)

El administrador mantiene un listado de repuestos con nombre y precio desde
**Repuestos → Nuevo repuesto**. Puede cargarlo antes de registrar compras y editar
el nombre o precio de cada artículo desde el listado.

La opción **Eliminar** pide confirmación y retira el artículo del listado y de las
sugerencias. Si ya se usó en órdenes, sus líneas conservan descripción, cantidades,
costos, margen e importes; se desvinculan del catálogo. Se puede volver a cargar
un artículo con el mismo nombre después de eliminarlo.

El precio del catálogo es un **costo unitario de referencia**. Al agregar un
repuesto a una orden, se usa para autocompletar el costo; el margen del taller se
aplica después para calcular el precio al cliente. No se administran existencias,
entradas, salidas ni disponibilidad física. La cantidad pertenece exclusivamente
al repuesto cargado en la orden.

## Uso en órdenes

Desde **Órdenes → detalle → Agregar repuesto**, escribir una descripción filtra las
sugerencias del catálogo. Al seleccionar **Usar**, se completan la descripción y
el costo unitario. El administrador puede ajustar el costo para esa compra y cargar
cantidad, margen y proveedor opcional. También puede registrar un repuesto ocasional
sin seleccionarlo del catálogo.

Guardar un repuesto en una orden no crea artículos ni modifica los precios del
catálogo. El catálogo se administra explícitamente desde **Repuestos**. Los nombres
se normalizan en mayúsculas y espacios para evitar duplicados; para distinguir
marcas o modelos, incluirlos en el nombre.

Cada compra conserva descripción, cantidad, costo real, margen, proveedor opcional,
administrador y fecha de registro. Los cambios posteriores del catálogo o del
margen configurado no alteran compras anteriores. El precio al cliente se calcula
con decimales y se guarda redondeado a dos posiciones:

```text
precio_cliente = costo_unitario × cantidad × (1 + margen / 100)
ganancia = precio_cliente − costo_unitario × cantidad
```

Si se omite el margen, se usa el configurado en el taller. El costo unitario debe
enviarse explícitamente al guardar la compra, incluso cuando se selecciona un
artículo del catálogo. Una orden cerrada no admite compras. Este ticket incorpora
la carga necesaria para utilizar el catálogo, alineada con los campos de HU03
(#20); no agrega edición o eliminación de compras.

## Aviso del mecánico y valorización (HU14)

Un mecánico sin acceso al catálogo ni a los costos puede avisar, desde el detalle
de una orden abierta, que usó un repuesto. Solo carga **descripción** y
**cantidad**; no envía costo, margen ni precio. La compra queda con estado
`pendiente_de_valorizar` y sin costo, margen ni precio al cliente.

Administración ve estas compras marcadas como "pendiente de valorizar" en el
listado de la orden y completa el costo real (y opcionalmente el margen, que si
se omite usa el configurado en el taller) desde **Cargar costo**. Al guardarlo, la
compra pasa a estado `valorizado` y se calcula el precio al cliente con la misma
fórmula que una compra directa. Un repuesto ya valorizado no se puede volver a
valorizar, y no se puede valorizar en una orden cerrada.

Una orden con compras pendientes de valorizar no se puede cerrar: la validación
vive en el modelo `Orden`, de modo que cualquier camino que intente cerrarla
(incluido un futuro flujo de cierre y cobro) queda bloqueado mientras existan
compras sin costo cargado.

## API

Todos estos endpoints requieren JWT. Salvo donde se indica, son de administrador;
un mecánico recibe 403 y sin sesión se devuelve 401. Los importes se devuelven
como cadenas decimales.

| Método y ruta | Uso |
| --- | --- |
| `GET /repuestos_catalogo?buscar=filtro&pagina=1` | Catálogo con `id`, `nombre`, `precio` y metadatos de paginación |
| `POST /repuestos_catalogo` | Cargar nombre y precio en el catálogo |
| `PATCH /repuestos_catalogo/:id` | Editar nombre y/o precio del catálogo |
| `DELETE /repuestos_catalogo/:id` | Eliminar del catálogo conservando las líneas de las órdenes; devuelve 204 |
| `GET /ordenes/:orden_id/repuestos?pagina=1` | Compras registradas en esa orden, con precio y ganancia |
| `POST /ordenes/:orden_id/repuestos` | Administrador: registra una compra valorizada. Mecánico: avisa un repuesto pendiente de valorizar (solo `descripcion` y `cantidad`) |
| `PATCH /ordenes/:orden_id/repuestos/:id/valorizar` | Administrador: carga el costo (y opcionalmente el margen) de un aviso pendiente |

Los listados aceptan `por_pagina` (20 por defecto, máximo 100).

Ejemplo de alta o edición del catálogo:

```json
{
  "repuesto_catalogo": {
    "nombre": "Filtro de aceite",
    "precio": "12500.50"
  }
}
```

Ejemplo de compra a partir del catálogo:

```json
{
  "repuesto": {
    "repuesto_catalogo_id": 1,
    "cantidad": 2,
    "costo_unitario": "12500.50",
    "margen": "25",
    "proveedor": "Repuestos Centro"
  }
}
```

Para una descripción ocasional, reemplazar `repuesto_catalogo_id` por `descripcion`.
La cantidad debe ser entera y positiva; el costo, no negativo; el margen, entre 0
y 100. Los nombres del catálogo son únicos y tienen hasta 200 caracteres; su precio
es no negativo y menor que 10000000000. Los errores de validación devuelven 422 con
mensajes por campo.

Ejemplo de aviso de un mecánico:

```json
{
  "repuesto": {
    "descripcion": "Filtro de aceite",
    "cantidad": 2
  }
}
```

Ejemplo de valorización de ese aviso por administración:

```json
{
  "repuesto": {
    "costo_unitario": "12500.50",
    "margen": "25"
  }
}
```

## Migración y verificación

Aplicar `bin/rails db:migrate`. La nueva migración conserva los artículos existentes
y renombra `ultimo_costo` a `precio`, manteniendo sus valores. Los clientes de la
API deben usar el nuevo campo `precio` del catálogo.

1. Ingresar como administrador y cargar un repuesto con precio 100 desde **Repuestos**.
2. Editarlo y cambiar el precio a 120, sin abrir ninguna orden.
3. En una orden abierta, escribir parte del nombre y seleccionar **Usar**: se
   completan descripción y costo 120.
4. Registrar cantidad 2, costo 130 y margen 25: el precio al cliente debe ser 325.
5. Confirmar que el catálogo conserva 120 y que se puede reutilizar el artículo.
6. Editar el catálogo a 150: la compra anterior conserva costo 130 y total 325.
7. Registrar un repuesto ocasional y confirmar que no se agrega al catálogo.
8. Verificar que una orden cerrada no ofrece carga y un mecánico no accede al catálogo.
9. Eliminar el artículo desde **Repuestos**: cancelar conserva el artículo;
   confirmar lo quita del catálogo y de las sugerencias, conservando las compras
   anteriores. Un mecánico no puede eliminar artículos.
10. Como mecánico, entrar a una orden abierta y avisar un repuesto con
    descripción y cantidad: queda "pendiente de valorizar", sin costo.
11. Como administrador, cargar el costo de ese aviso desde **Cargar costo**: pasa
    a valorizado y muestra precio al cliente y ganancia.
12. Confirmar que no se puede cerrar la orden mientras tenga avisos pendientes
    de valorizar.

Pruebas automatizadas:

RSpec exige que el nombre de la base termine en `_test`. Si el entorno define
`DATABASE_URL`, esa variable puede reemplazar la base de `config/database.yml`,
incluso con `RAILS_ENV=test`: apuntarla siempre a una base exclusiva para pruebas.
La demo local usa `metodologias_hu18_demo`; las pruebas, `metodologias_hu18_test`.

```sh
bundle exec rspec spec/services/repuesto_agregar_spec.rb spec/services/repuesto_avisar_spec.rb \
  spec/services/repuesto_valorizar_spec.rb spec/requests/repuestos_spec.rb \
  spec/requests/repuestos_catalogo_spec.rb spec/models/orden_spec.rb
bin/rubocop
cd frontend
npm run build
npm run lint
```
