require "json"

module Mcp
  class Herramientas
    ESTADOS_ORDEN = %w[abierta cerrada cancelada].freeze
    LIMITE = 20

    def self.definiciones
      REGISTRO.map { |nombre, datos| datos.merge(name: nombre) }
    end

    def self.llamar(nombre, argumentos, usuario)
      raise Fallo.new(:parametros, "No existe la herramienta #{nombre}.") unless REGISTRO.key?(nombre)
      raise Fallo.new(:parametros, "Los argumentos tienen que ser un objeto.") unless argumentos.is_a?(Hash)

      send(nombre, Argumentos.new(argumentos), usuario)
    end

    def self.buscar_ordenes(args, usuario)
      termino = args.texto(:termino).to_s
      estado = args.opcion(:estado, ESTADOS_ORDEN)
      estado ||= "abierta" if termino.blank?
      ordenes = Orden.includes(:cliente, :vehiculo).order(created_at: :desc, id: :desc)
      ordenes = ordenes.where(estado: estado) if estado
      ordenes = OrdenBuscar.call(termino, scope: ordenes).limit(LIMITE)
      texto({ ordenes: ordenes.map { |orden| presentar_orden(orden, usuario) }, limite: LIMITE })
    end

    def self.buscar_vehiculos(args, usuario)
      exigir_administrador!(usuario)
      termino = args.texto(:termino, obligatorio: true)
      vehiculos = VehiculoBuscar.call(termino).limit(LIMITE).includes(:cliente)
      texto({ vehiculos: vehiculos.map { |vehiculo|
        {
          id: vehiculo.id,
          patente: vehiculo.patente,
          marca: vehiculo.marca,
          modelo: vehiculo.modelo,
          anio: vehiculo.anio,
          cliente: vehiculo.cliente.nombre
        }
      } })
    end

    def self.ver_tareas(_args, usuario)
      exigir_mecanico!(usuario)
      texto({
        mias: listar(en_curso(usuario)),
        disponibles: listar(disponibles),
        terminadas_hoy: listar(terminadas_hoy(usuario))
      })
    end

    def self.tomar_tarea(args, usuario)
      exigir_mecanico!(usuario)
      tarea = TareaTomar.call(tarea: tarea_con_orden(args), mecanico: usuario)
      texto(presentar_tarea(tarea))
    end

    def self.completar_tarea(args, usuario)
      exigir_mecanico!(usuario)
      tarea = tarea_propia(args, usuario)
      texto(presentar_tarea(TareaCompletar.call(tarea: tarea)))
    end

    def self.liberar_tarea(args, usuario)
      exigir_mecanico!(usuario)
      tarea = tarea_propia(args, usuario)
      texto(presentar_tarea(TareaLiberar.call(tarea: tarea)))
    end

    def self.abrir_orden(args, usuario)
      exigir_administrador!(usuario)
      orden = OrdenAbrir.call(vehiculo_id: vehiculo_de(args).id, motivo: args.texto(:motivo, obligatorio: true))
      texto(presentar_orden(orden, usuario))
    end

    def self.agregar_repuesto(args, usuario)
      orden = Orden.find(args.entero(:orden_id, obligatorio: true))
      descripcion = args.texto(:descripcion, obligatorio: true)
      cantidad = args.entero(:cantidad, obligatorio: true)
      if usuario.administrador?
        repuesto = RepuestoAgregar.call(
          orden: orden, registrado_por: usuario, descripcion: descripcion, cantidad: cantidad,
          costo_unitario: args.decimal(:costo_unitario, obligatorio: true), margen: args.decimal(:margen),
          proveedor: args.texto(:proveedor)
        )
        texto({
          id: repuesto.id, descripcion: repuesto.descripcion, cantidad: repuesto.cantidad, estado: repuesto.estado,
          precio_cliente: repuesto.precio_cliente.to_s("F")
        })
      else
        repuesto = RepuestoAvisar.call(orden: orden, registrado_por: usuario, descripcion: descripcion, cantidad: cantidad)
        texto({ id: repuesto.id, descripcion: repuesto.descripcion, cantidad: repuesto.cantidad, estado: repuesto.estado })
      end
    end

    def self.ver_presupuesto(args, usuario)
      exigir_administrador!(usuario)
      presupuesto = OrdenCalcularPresupuesto.call(orden: Orden.find(args.entero(:orden_id, obligatorio: true)))
      texto({
        orden_id: presupuesto.orden.id,
        presupuesto: presupuesto.presupuesto.to_s("F"),
        total_aseguradora: presupuesto.total_aseguradora.to_s("F"),
        tareas: presupuesto.tareas.map { |tarea|
          { id: tarea.id, descripcion: tarea.descripcion, estado: tarea.estado, precio: tarea.precio&.to_s("F") }
        },
        repuestos: presupuesto.repuestos.map { |repuesto|
          { id: repuesto.id, descripcion: repuesto.descripcion, cantidad: repuesto.cantidad, estado: repuesto.estado,
            precio_cliente: repuesto.precio_cliente&.to_s("F") }
        }
      })
    end

    def self.ver_total_parcial(args, usuario)
      exigir_administrador!(usuario)
      total = OrdenCalcularTotalParcial.call(orden: Orden.find(args.entero(:orden_id, obligatorio: true)))
      texto({
        orden_id: total.orden.id,
        mano_de_obra: total.mano_de_obra.to_s("F"),
        total_repuestos: total.total_repuestos.to_s("F"),
        total: total.total.to_s("F"),
        a_cobrar_hoy: total.a_cobrar_hoy.to_s("F")
      })
    end

    def self.cerrar_orden(args, usuario)
      exigir_administrador!(usuario)
      orden = OrdenCerrar.call(
        orden: Orden.find(args.entero(:orden_id, obligatorio: true)),
        cerrada_por: usuario,
        descartar_pendientes: args.booleano(:descartar_pendientes),
        franquicia: args.decimal(:franquicia)
      )
      texto({ id: orden.id, estado: orden.estado, total_cerrado: orden.total_cerrado.to_s("F") })
    end

    def self.exigir_administrador!(usuario)
      return if usuario.administrador?

      raise Fallo.new(:prohibido, "Solo recepción puede hacer esto.")
    end

    def self.exigir_mecanico!(usuario)
      return if usuario.mecanico?

      raise Fallo.new(:prohibido, "Solo un mecánico puede hacer esto.")
    end

    def self.vehiculo_de(args)
      id = args.entero(:vehiculo_id)
      return Vehiculo.find(id) if id

      patente = Vehiculo.normalize_value_for(:patente, args.texto(:patente, obligatorio: true))
      Vehiculo.find_by!(patente: patente)
    end

    def self.tarea_con_orden(args)
      Tarea.includes(orden: %i[cliente vehiculo]).find(args.entero(:tarea_id, obligatorio: true))
    end

    def self.tarea_propia(args, usuario)
      tarea = tarea_con_orden(args)
      return tarea if tarea.mecanico_id == usuario.id

      raise Fallo.new(:prohibido, "Solo quien tomó la tarea puede hacer esto.")
    end

    def self.en_curso(usuario)
      base_tareas.en_curso.where(mecanico: usuario).order(:tomada_en, :id)
    end

    def self.disponibles
      base_tareas.pendiente.where.not(aprobacion: :rechazada).order(:created_at, :id)
    end

    def self.terminadas_hoy(usuario)
      Tarea.where(mecanico: usuario, estado: :terminada, terminada_en: Time.zone.today.all_day)
        .includes(orden: %i[cliente vehiculo], notas: :registrado_por)
        .order(terminada_en: :desc)
    end

    def self.base_tareas
      Tarea.joins(:orden).merge(Orden.abierta).includes(orden: %i[cliente vehiculo], notas: :registrado_por)
    end

    def self.listar(tareas)
      tareas.map { |tarea| presentar_tarea(tarea) }
    end

    def self.presentar_tarea(tarea)
      {
        id: tarea.id,
        orden_id: tarea.orden_id,
        descripcion: tarea.descripcion,
        estado: tarea.estado,
        aprobacion: tarea.aprobacion,
        patente: tarea.orden.vehiculo.patente,
        cliente: tarea.orden.cliente.nombre,
        notas: tarea.notas.sort_by(&:created_at).map { |nota|
          { contenido: nota.contenido, registrado_por: nota.registrado_por.nombre }
        }
      }
    end

    def self.presentar_orden(orden, usuario)
      datos = {
        id: orden.id,
        estado: orden.estado,
        motivo: orden.motivo,
        cliente: orden.cliente.nombre,
        vehiculo: orden.vehiculo.as_json(only: %i[id patente marca modelo anio])
      }
      return datos unless usuario.administrador?

      datos.merge(telefono: orden.cliente.telefono, total_cerrado: orden.total_cerrado&.to_s("F"))
    end

    def self.texto(datos)
      { content: [ { type: "text", text: JSON.generate(datos) } ] }
    end

    def self.esquema(propiedades, requeridos = [])
      { type: "object", properties: propiedades, required: requeridos }
    end

    def self.texto_prop(descripcion)
      { type: "string", description: descripcion }
    end

    def self.entero_prop(descripcion)
      { type: "integer", description: descripcion }
    end

    REGISTRO = {
      "buscar_ordenes" => {
        description: "Busca órdenes por patente, cliente, teléfono o vehículo. Sin término lista las abiertas. Recepción y mecánico. Los importes solo aparecen para recepción.",
        inputSchema: esquema({
          termino: texto_prop("Patente, cliente, teléfono o vehículo"),
          estado: texto_prop("abierta, cerrada o cancelada")
        })
      },
      "buscar_vehiculos" => {
        description: "Busca vehículos por patente o cliente para conseguir el id antes de abrir una orden. Solo recepción.",
        inputSchema: esquema({ termino: texto_prop("Patente o cliente") }, %w[termino])
      },
      "ver_tareas" => {
        description: "Lista las tareas disponibles, las que este mecánico tiene en curso y las que terminó hoy. Solo un mecánico.",
        inputSchema: esquema({})
      },
      "tomar_tarea" => {
        description: "Toma una tarea pendiente para el mecánico de la sesión. Falla si otro la tomó al mismo tiempo. Solo un mecánico.",
        inputSchema: esquema({ tarea_id: entero_prop("Id de la tarea") }, %w[tarea_id])
      },
      "completar_tarea" => {
        description: "Marca como terminada una tarea que este mecánico tiene en curso. Solo un mecánico.",
        inputSchema: esquema({ tarea_id: entero_prop("Id de la tarea") }, %w[tarea_id])
      },
      "liberar_tarea" => {
        description: "Suelta una tarea en curso de este mecánico y la deja disponible. Solo un mecánico.",
        inputSchema: esquema({ tarea_id: entero_prop("Id de la tarea") }, %w[tarea_id])
      },
      "abrir_orden" => {
        description: "Abre una orden para un vehículo ya cargado. Pasá vehiculo_id o patente, y el motivo. Solo recepción. Un vehículo no puede tener dos órdenes abiertas.",
        inputSchema: esquema({
          vehiculo_id: entero_prop("Id del vehículo"),
          patente: texto_prop("Patente, si no se manda vehiculo_id"),
          motivo: texto_prop("Motivo de ingreso")
        }, %w[motivo])
      },
      "agregar_repuesto" => {
        description: "Carga un repuesto comprado al momento en una orden abierta. Recepción manda costo_unitario y, si quiere, margen y proveedor. Un mecánico solo avisa el uso, sin precio.",
        inputSchema: esquema({
          orden_id: entero_prop("Id de la orden"),
          descripcion: texto_prop("Nombre del repuesto"),
          cantidad: entero_prop("Cantidad"),
          costo_unitario: { type: "number", description: "Costo real unitario. Solo recepción." },
          margen: { type: "number", description: "Margen porcentual. Solo recepción. Si falta, usa el del taller." },
          proveedor: texto_prop("Proveedor. Solo recepción.")
        }, %w[orden_id descripcion cantidad])
      },
      "ver_presupuesto" => {
        description: "Calcula el presupuesto de una orden abierta: mano de obra más repuestos. Solo recepción.",
        inputSchema: esquema({ orden_id: entero_prop("Id de la orden") }, %w[orden_id])
      },
      "ver_total_parcial" => {
        description: "Calcula el total parcial a cobrar de una orden abierta. Solo recepción.",
        inputSchema: esquema({ orden_id: entero_prop("Id de la orden") }, %w[orden_id])
      },
      "cerrar_orden" => {
        description: "Cierra una orden abierta y registra el total. Solo recepción, y solo después de que la persona confirmó el cierre. Si hay tareas en curso, falla. Con descartar_pendientes en true cancela las que nadie tomó.",
        inputSchema: esquema({
          orden_id: entero_prop("Id de la orden"),
          descartar_pendientes: { type: "boolean", description: "Cancela las tareas que nadie tomó" },
          franquicia: { type: "number", description: "Franquicia a descontar del total, si corresponde" }
        }, %w[orden_id])
      }
    }.freeze

    private_class_method :buscar_ordenes, :buscar_vehiculos, :ver_tareas, :tomar_tarea, :completar_tarea,
      :liberar_tarea, :abrir_orden, :agregar_repuesto, :ver_presupuesto, :ver_total_parcial, :cerrar_orden,
      :exigir_administrador!, :exigir_mecanico!, :vehiculo_de, :tarea_con_orden, :tarea_propia, :en_curso,
      :disponibles, :terminadas_hoy, :base_tareas, :listar, :presentar_tarea, :presentar_orden, :texto,
      :esquema, :texto_prop, :entero_prop
  end
end
