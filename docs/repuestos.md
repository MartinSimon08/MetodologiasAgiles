# Catálogo de repuestos (HU18)

El administrador consulta el catálogo desde **Repuestos** y registra compras desde
**Órdenes → detalle → Agregar repuesto**. Puede seleccionar un artículo para copiar
su descripción y último costo unitario, revisar el costo real y guardar la compra.
También puede escribir una descripción nueva sin seleccionar un artículo.

El catálogo se alimenta automáticamente de las compras registradas. La descripción
identifica al artículo: se normalizan mayúsculas y espacios para reutilizarlo sin
duplicados. Para distinguir marcas o modelos, incluirlos en la descripción.
La búsqueda muestra todos los artículos coincidentes, con paginación.

El último costo es el costo unitario de la última compra registrada correctamente,
no un promedio ni un precio de venta. Puede aumentar, disminuir o ser cero. Al
seleccionar un artículo, el costo se sugiere en el formulario, pero debe enviarse
explícitamente al guardar; la API no lo sustituye de forma silenciosa.

Cada compra conserva descripción, cantidad, costo real, margen, proveedor opcional,
administrador y fecha de registro. El precio al cliente se calcula con decimales,
se redondea a dos posiciones y se guarda en la línea:

```text
precio_cliente = costo_unitario × cantidad × (1 + margen / 100)
ganancia = precio_cliente − costo_unitario × cantidad
```

Cuando se omite el margen, se copia el configurado en el taller. Los cambios
posteriores de costo o margen no alteran las compras anteriores. La compra y la
actualización del catálogo se guardan en una transacción, con bloqueos de la orden
y del artículo. Una compra inválida o una orden cerrada no modifican el catálogo.

No se administran existencias: la cantidad pertenece exclusivamente a la compra.
Este ticket incorpora la carga necesaria para utilizar el catálogo, alineada con
los campos de HU03 (#20); no agrega edición o eliminación de compras.

## API

Todos estos endpoints requieren JWT de administrador. Los importes se devuelven
como cadenas decimales. Un mecánico recibe 403; sin sesión se devuelve 401.

| Método y ruta | Uso |
| --- | --- |
| `GET /repuestos_catalogo?buscar=filtro&pagina=1` | Catálogo con `id`, `nombre`, `ultimo_costo` y metadatos de paginación |
| `GET /ordenes/:orden_id/repuestos?pagina=1` | Compras registradas en esa orden, con precio y ganancia |
| `POST /ordenes/:orden_id/repuestos` | Registrar una compra y actualizar el catálogo |

Los listados aceptan `por_pagina` (20 por defecto, máximo 100).

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

Para una descripción nueva, reemplazar `repuesto_catalogo_id` por `descripcion`.
La cantidad debe ser entera y positiva; el costo, no negativo; el margen, entre 0
y 100. Los errores de validación devuelven 422 con mensajes por campo.

## Verificación manual

1. Aplicar `bin/rails db:migrate` e ingresar como administrador.
2. En una orden abierta, registrar un repuesto nuevo con costo 100 y cantidad 2.
3. Buscarlo en **Repuestos**: el último costo debe ser 100.
4. En otra orden, seleccionarlo y cambiar el costo sugerido de 100 a 120.
5. Confirmar que el catálogo muestra 120 y la primera compra conserva costo 100.
6. Verificar que una orden cerrada no ofrece carga y un mecánico no accede al catálogo.

Pruebas automatizadas: `bundle exec rspec spec/services/repuesto_agregar_spec.rb spec/requests/repuestos_spec.rb`.
