# Modelo de datos

Refleja el esquema actual (`db/schema.rb`): `Usuario`, `Cliente`, `Orden` y `Tarea`. `Repuesto` y `Pago` todavía no están implementados; se muestran en gris porque son el próximo paso natural (repuestos comprados al vuelo y cargados directo a la orden, sin catálogo ni stock permanente — ver AGENTS.md) y ayudan a leer el modelo completo del producto.

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
        datetime tomada_en
        datetime terminada_en
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
