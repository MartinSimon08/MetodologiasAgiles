module Paginable
  extend ActiveSupport::Concern

  POR_PAGINA_DEFAULT = 20
  POR_PAGINA_MAX = 100

  private

  def paginar(scope)
    por_pagina = params.fetch(:por_pagina, POR_PAGINA_DEFAULT).to_i.clamp(1, POR_PAGINA_MAX)
    total = scope.count
    total_paginas = [ (total.to_f / por_pagina).ceil, 1 ].max
    pagina = params.fetch(:pagina, 1).to_i.clamp(1, total_paginas)

    registros = scope.offset((pagina - 1) * por_pagina).limit(por_pagina)
    meta = { pagina: pagina, por_pagina: por_pagina, total: total, total_paginas: total_paginas }

    [ registros, meta ]
  end
end
