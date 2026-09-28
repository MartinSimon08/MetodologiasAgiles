# Modelo de datos

Refleja el esquema actual (`db/schema.rb`): `Usuario`, `Cliente`, `Orden`, `Tarea` y `TareaFrecuente`. `Repuesto` y `Pago` todavía no están implementados; se muestran en gris porque son el próximo paso natural (repuestos comprados al vuelo y cargados directo a la orden, sin catálogo ni stock permanente — ver AGENTS.md) y ayudan a leer el modelo completo del producto.

`TareaFrecuente` es un catálogo simple (sin relación en base de datos con `Tarea`): al crear una tarea en una orden, el frontend puede prellenar la descripción y el precio con una entrada del catálogo, pero el valor sugerido se copia a la tarea y queda editable, no se referencia por FK.

```mermaid
erDiagram
    CLIENTE ||--o{ ORDEN : solicita
    ORDEN ||--o{ TAREA : incluye
    USUARIO ||--o{ TAREA : realiza
    ORDEN ||--o{ REPUESTO : consume
    ORDEN ||--o| PAGO : genera

    CLIENTE {
        int id PK
        string nombre
        string telefono
        string email "opcional"
        datetime created_at
    }

    USUARIO {
        int id PK
        string nombre
        string email
        string rol
        string password_digest
    }

    ORDEN {
        int id PK
        int cliente_id FK
        string vehiculo
        string estado "abierta | cerrada"
        datetime created_at
    }

    TAREA {
        int id PK
        int orden_id FK
        int mecanico_id FK "nullable"
        string descripcion
        string estado "pendiente | en_curso | terminada"
        decimal precio "mano de obra, nullable"
        datetime tomada_en
        datetime terminada_en
    }

    TAREA_FRECUENTE {
        int id PK
        string descripcion "única"
        decimal precio_sugerido
    }

    REPUESTO {
        int id PK "pendiente de implementar"
        int orden_id FK
        string nombre
        decimal costo_real
        decimal margen
        int cantidad
    }

    PAGO {
        int id PK "pendiente de implementar"
        int orden_id FK
        decimal monto
        string medio_pago
        datetime pagado_en
    }
```
