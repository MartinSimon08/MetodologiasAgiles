# Privacidad de Gestión de Taller

Gestión de Taller guarda los datos de un único taller mecánico para coordinar el trabajo del día. No es una red social ni un directorio público de clientes.

Qué se guarda: usuarios del taller (nombre, email, rol y una contraseña hasheada), clientes, vehículos, órdenes de trabajo, tareas, notas de las tareas, repuestos con su costo y su margen, comprobantes adjuntos, adelantos, y aseguradoras o casos cuando la orden los usa.

Quién lo ve: un administrador ve la operación del taller. Un mecánico ve las tareas y lo necesario para hacerlas. Esos datos no se publican en estas páginas. Sin sesión, la API responde 401 y no entrega la orden, el cliente ni el vehículo.

La sesión es un JWT. El navegador lo envía como `Authorization: Bearer`. El servidor puede devolver un token renovado en el header `X-Token-Renovado`. Dejar de enviar ese token cierra el acceso desde ese navegador.

No vendemos datos ni los mezclamos con otros talleres. Hay una sola base para ese taller. El código del programa es público, con licencia MIT, en el [repositorio](https://github.com/MartinSimon08/MetodologiasAgiles). El contenido de las órdenes no está en el repositorio.

Para preguntar por el software, la [página de contacto](/contact) indica el repositorio. Para pedir un dato de un cliente del taller, hay que hablar con el taller, no con esta página.

## Páginas

- [Inicio](/)
- [Acerca de](/about)
- [Contacto](/contact)
- [Documentación de la API](/docs)
- [llms.txt](/llms.txt)
