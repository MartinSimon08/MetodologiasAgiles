class ReporteTareasFrecuentes
  Fila = Data.define(:descripcion, :cantidad)

  DESCRIPCION_CLAVE = "LOWER(unaccent(tareas.descripcion))"

  def self.call
    Tarea.terminada
         .group(Arel.sql(DESCRIPCION_CLAVE))
         .select(
           Arel.sql(
             "(ARRAY_AGG(tareas.descripcion ORDER BY tareas.terminada_en DESC, tareas.id DESC))[1] AS descripcion"
           ),
           Arel.sql("COUNT(*) AS cantidad")
         )
         .order(Arel.sql("COUNT(*) DESC, descripcion ASC"))
         .map { |fila| Fila.new(descripcion: fila[:descripcion], cantidad: fila[:cantidad].to_i) }
  end
end
