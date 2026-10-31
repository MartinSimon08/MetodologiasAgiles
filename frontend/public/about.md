# Acerca de Gestión de Taller

Gestión de Taller existe para un taller mecánico que coordina el día con un cuaderno y con WhatsApp. El programa no intenta ser un ERP. El centro es la orden de trabajo.

Cuando entra un vehículo, la recepción abre una orden del cliente. La orden junta el vehículo, las tareas, los repuestos que se compran en el momento y el cobro. Las tareas no se asignan: quedan disponibles y cualquier mecánico libre las toma, las termina o las libera. Si dos intentan tomar la misma, uno solo se queda con ella.

Los repuestos no salen de un stock. Se anotan sobre la orden con el costo real y un margen. El catálogo, si se usa, guarda un costo de referencia para la próxima vez, no una cantidad en depósito. Las señas se registran con la orden abierta. Al cerrar, el total es la mano de obra más los repuestos.

La pantalla de recepción es para el administrador. La vista móvil es para el mecánico. La API es Ruby on Rails 8 y la interfaz es una PWA en React. El código es público, con licencia MIT, en el [repositorio](https://github.com/MartinSimon08/MetodologiasAgiles).

No hay sucursales, ni inventario permanente, ni planes de precio. Lo usa un taller. Los datos de los clientes no están en estas páginas: piden sesión.

## Páginas

- [Inicio](/)
- [Contacto](/contact)
- [Privacidad](/privacy)
- [Documentación de la API](/docs)
- [llms.txt](/llms.txt)
