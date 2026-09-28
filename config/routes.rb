Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resource :sesion, only: %i[show create], controller: "sesiones"
  resource :configuracion_taller, only: %i[show update], controller: "configuraciones_taller"

  resources :usuarios, only: %i[index create] do
    member do
      patch :resetear_password
    end
  end

  resources :clientes, only: %i[index create]

  resources :tareas_frecuentes, only: %i[index create]

  resources :ordenes, only: %i[index show] do
    resources :tareas, only: %i[index create], shallow: true do
      member do
        patch :tomar
        patch :completar
        patch :liberar
        patch :actualizar_precio
      end
    end
  end
end
