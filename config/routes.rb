Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  scope format: false do
    get "/llms.txt", to: "llms#show"
  end

  mount ActionCable.server => "/cable"

  resource :sesion, only: %i[show create], controller: "sesiones"
  resource :configuracion_taller, only: %i[show update], controller: "configuraciones_taller"

  resources :usuarios, only: %i[index create] do
    member do
      patch :resetear_password
      patch :desactivar
    end
  end

  resources :clientes, only: %i[index create]
  resources :aseguradoras, only: %i[index create update destroy] do
    member do
      patch :desactivar
      patch :activar
    end
  end
  resources :vehiculos, only: %i[index create] do
    collection do
      get :verificar_patente
    end
    member do
      patch :cambiar_duenio
    end
  end
  resources :repuestos_catalogo, only: %i[index create update destroy]
  resources :repuestos_por_proveedor, only: :index

  resources :tareas_frecuentes, only: %i[index create]
  resources :tareas_mecanico, only: :index

  resources :ordenes, only: %i[index show create] do
    resources :adelantos, only: %i[index create]
    resources :repuestos, only: %i[index create update destroy] do
      resources :ajustes, only: :create, controller: "ajustes_repuesto"
      member do
        patch :valorizar
        patch :aprobar
        patch :rechazar
        get :comprobante
        post :adjuntar_comprobante, path: :comprobante
      end
      collection do
        post :vista_previa
      end
    end
    resources :tareas, only: %i[index create], shallow: true do
      member do
        patch :tomar
        patch :completar
        patch :liberar
        patch :actualizar_precio
        patch :aprobar
        patch :rechazar
      end
      resources :notas, only: :create, controller: "tarea_notas"
    end

    member do
      patch :cancelar
      patch :cerrar
      get :resumen_cierre
      get :total_parcial
      get :presupuesto
    end
  end
end
