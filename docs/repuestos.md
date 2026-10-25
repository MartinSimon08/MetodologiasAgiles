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

Si se omite el margen al dar de alta, se usa el configurado en el taller. El costo
unitario debe enviarse explícitamente al guardar la compra, incluso cuando se
selecciona un artículo del catálogo. Una orden cerrada no admite compras. Este
ticket incorpora la carga necesaria para utilizar el catálogo, alineada con los
campos de HU03 (#20). Corregir o quitar una compra ya cargada corresponde a HU16.

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
compras sin costo cargado. Un aviso pendiente que se quitó deja de bloquear el
cierre.

## Corregir o quitar una compra (HU16)

Mientras la orden está abierta, el administrador puede corregir la cantidad, el
costo unitario, el margen o el proveedor de un repuesto ya valorizado. El precio
al cliente y la ganancia se recalculan con la misma fórmula y se vuelven a
guardar. La descripción, el vínculo con el catálogo y quién cargó la compra no
cambian. Si no se envía el margen, se conserva el que ya tenía la compra.

Un repuesto pendiente de valorizar admite corrección de cantidad y proveedor. El
costo y el margen se siguen cargando con valorizar.

Quitar un repuesto pide confirmación en la pantalla. La compra deja de sumar al
total y queda registrada: se guardan quién la quitó y cuándo, y sigue visible
como baja. No se borra la fila. Una orden cerrada o cancelada no admite
correcciones ni bajas. Si el total resultante quedaría por debajo de los
adelantos ya registrados, la operación se rechaza.

## Foto del comprobante (HU24)

En una orden abierta, el mecánico o el administrador pueden adjuntar una foto
del comprobante de compra a un repuesto para respaldar el gasto real. Hay una
sola foto por repuesto: subir otra reemplaza la anterior.

La foto queda en el repuesto, y el repuesto pertenece a la orden, así que el
comprobante sigue asociado a esa compra y a esa orden. Se consulta desde el
detalle, también si la orden se cerró o se canceló, y en las bajas registradas.

Formatos aceptados: JPG, PNG y WebP, hasta 8 MB. No se puede adjuntar en una
orden cerrada o cancelada, ni en un repuesto ya quitado. La foto que ya estaba
se sigue pudiendo ver.

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
| `GET /ordenes/:orden_id/repuestos?pagina=1` | Administrador y mecánico. Vigentes de la orden, con `comprobante` en `null` o con `nombre`, `content_type` y `byte_size`. El administrador recibe precio, ganancia y `quitados`. El mecánico no recibe costo, margen, precio, ganancia ni proveedor |
| `POST /ordenes/:orden_id/repuestos` | Administrador: registra una compra valorizada. Mecánico: avisa un repuesto pendiente de valorizar (solo `descripcion` y `cantidad`) |
| `PATCH /ordenes/:orden_id/repuestos/:id` | Administrador: corrige cantidad, costo, margen o proveedor de una compra en una orden abierta y recalcula el precio |
| `DELETE /ordenes/:orden_id/repuestos/:id` | Administrador: quita la compra del total y registra la baja. Responde el repuesto con `quitado_en` y `quitado_por` |
| `PATCH /ordenes/:orden_id/repuestos/:id/valorizar` | Administrador: carga el costo (y opcionalmente el margen) de un aviso pendiente |
| `POST /ordenes/:orden_id/repuestos/:id/comprobante` | Administrador y mecánico. Adjunta o reemplaza la foto (`multipart/form-data`, campo `comprobante`) en una orden abierta. Responde el repuesto |
| `GET /ordenes/:orden_id/repuestos/:id/comprobante` | Administrador y mecánico. Devuelve la imagen. Responde 404 si ese repuesto no tiene foto |
| `POST /ordenes/:orden_id/repuestos/:repuesto_id/ajustes` | Administrador: registra una devolución o un cambio sobre el repuesto original |

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

Ejemplo de corrección de una compra valorizada. El precio al cliente se recalcula
en el servidor. Para quitarla, `DELETE` sobre la misma ruta, sin cuerpo.

```json
{
  "repuesto": {
    "cantidad": 3,
    "costo_unitario": "100.50",
    "margen": "20",
    "proveedor": "Casa Norte"
  }
}
```

## Devolución o cambio (HU35)

Un administrador puede registrar, sobre un repuesto ya valorizado de una orden
abierta, que unas unidades se devolvieron al proveedor o se cambiaron por una
falla. El registro original no se modifica: descripción, cantidad, costo,
margen, precio al cliente y quién lo cargó quedan como estaban. Cada devolución
o cambio se agrega al historial de ese repuesto.

La cantidad del ajuste no puede superar las unidades que todavía no se
devolvieron ni cambiaron. Una misma unidad no se ajusta dos veces. Un repuesto
ya quitado de la orden tampoco acepta un ajuste.

En una devolución, el precio al cliente de esas unidades sale del total de la
orden. El costo unitario acreditado es el que informa recepción y puede ser
menor que el original si el proveedor no reintegra el total. En un cambio, esas
unidades siguen en la orden y su precio al cliente se recalcula con el costo
del reemplazo y el margen original. Si el costo no cambia, el total queda igual
y el historial se conserva igual.

El total de una orden abierta suma la mano de obra de las tareas que siguen en
la orden, el precio original de los repuestos vigentes valorizados y estos
ajustes. Los repuestos quitados no entran. Si el resultado quedaría por debajo
de los adelantos ya registrados, el ajuste se rechaza. Quitar el repuesto lo
saca del total junto con sus ajustes.

Una orden cerrada conserva el total congelado y no acepta devoluciones ni
cambios. Para corregirla hay que reabrirla. Una orden cancelada tampoco acepta
el ajuste. Un repuesto pendiente de valorizar tiene que tener el costo cargado
antes.

```json
{
  "ajuste": {
    "tipo": "devolucion",
    "cantidad": 1,
    "costo_unitario": "12500.50",
    "motivo": "Falla de fábrica, el proveedor lo recibió"
  }
}
```

`tipo` también puede ser `cambio`. En ese caso `costo_unitario` es el costo del
reemplazo. La respuesta trae el ajuste de costo, el ajuste de precio al cliente
y la porción del precio original afectada. El listado de la orden incluye ese
historial, el precio vigente y las unidades que todavía se pueden ajustar.
El mecánico no ve costos, márgenes, precios ni el historial.

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
    de valorizar. Todavía no hay endpoint ni pantalla para cerrar una orden, así
    que este paso se verifica con los tests de `spec/models/orden_spec.rb`, no
    a mano.
13. En una orden abierta, corregir cantidad, costo, margen o proveedor de una
    compra valorizada: el precio al cliente y la ganancia cambian al guardar.
14. Quitar un repuesto: cancelar lo deja en la orden; confirmar lo saca del
    total y lo muestra en **Bajas registradas**, con quién lo quitó y cuándo.
15. En una orden cerrada no aparecen **Corregir** ni **Quitar**.
16. Si la corrección o la baja dejarían el total por debajo de un adelanto ya
    registrado, el sistema la rechaza y la compra no cambia.
17. En una orden abierta, como mecánico, adjuntar una foto JPG, PNG o WebP a un
    repuesto y abrirla con **Ver comprobante**.
18. Reemplazar la foto y confirmar que se ve la nueva.
19. Como administrador, abrir **Cargar costo** de un aviso que tenga foto y
    consultar el comprobante. En una orden cerrada no aparece **Adjuntar foto**,
    y la foto ya cargada se sigue viendo.
20. Como administrador, en un repuesto valorizado de una orden abierta, registrar
    una devolución de parte de las unidades. El renglón original conserva costo
    y precio, el historial muestra la devolución y el precio vigente baja.
21. Registrar un cambio con otro costo unitario. El historial muestra el costo
    del reemplazo y el precio vigente usa el margen original.
22. Confirmar que no se puede devolver o cambiar más unidades que las que siguen
    disponibles, ni hacerlo en una orden cerrada, cancelada o sobre un repuesto
    ya quitado. El total congelado no se modifica.

Pruebas automatizadas:

RSpec exige que el nombre de la base termine en `_test`. Si el entorno define
`DATABASE_URL`, esa variable puede reemplazar la base de `config/database.yml`,
incluso con `RAILS_ENV=test`: apuntarla siempre a una base exclusiva para pruebas.
La demo local usa `metodologias_hu18_demo`; las pruebas, `metodologias_hu18_test`.

```sh
bundle exec rspec spec/services/repuesto_agregar_spec.rb spec/services/repuesto_avisar_spec.rb \
  spec/services/repuesto_valorizar_spec.rb spec/services/repuesto_editar_spec.rb \
  spec/services/repuesto_quitar_spec.rb spec/services/repuesto_adjuntar_comprobante_spec.rb \
  spec/services/repuesto_registrar_ajuste_spec.rb \
  spec/requests/repuestos_spec.rb spec/requests/ajustes_repuesto_spec.rb \
  spec/requests/repuestos_catalogo_spec.rb spec/requests/autorizacion_por_rol_spec.rb \
  spec/models/orden_spec.rb
bin/rubocop
cd frontend
npm run build
npm run lint
```
