module Oauth
  class RegistrarCliente
    GRANTS = %w[authorization_code refresh_token].freeze

    def self.call(params)
      nombre = params[:client_name].to_s.strip
      uris = lista_de_uris(params[:redirect_uris])
      exigir_publico!(params[:token_endpoint_auth_method])
      raise Error.new("invalid_client_metadata", "Falta el nombre del cliente.") if nombre.blank? || nombre.length > 80
      raise Error.new("invalid_redirect_uri", "Hay una URI de redirección que no está permitida.") unless uris_validas?(uris)
      grants = lista(params[:grant_types], GRANTS)
      raise Error.new("invalid_client_metadata", "El grant no está soportado.") unless grants.include?("authorization_code") && (grants - GRANTS).empty?

      tipos = lista(params[:response_types], [ "code" ])
      raise Error.new("invalid_client_metadata", "Solo se admite response_type=code.") unless tipos == [ "code" ]

      cliente = OauthCliente.create!(
        client_id: "mcp_#{SecureRandom.urlsafe_base64(24)}",
        nombre: nombre,
        redirect_uris: uris,
        origen: "registro"
      )
      {
        client_id: cliente.client_id,
        client_name: cliente.nombre,
        redirect_uris: cliente.redirect_uris,
        grant_types: GRANTS,
        response_types: [ "code" ],
        token_endpoint_auth_method: "none",
        client_id_issued_at: cliente.created_at.to_i
      }
    end

    def self.lista_de_uris(valor)
      return valor if valor.is_a?(Array) && valor.all? { |uri| uri.is_a?(String) }

      nil
    end

    def self.uris_validas?(uris)
      uris.is_a?(Array) && uris.size.between?(1, 5) && uris.all? { |uri| RedirectUri.permitida?(uri) }
    end

    def self.exigir_publico!(metodo)
      return if metodo.blank? || metodo == "none"

      raise Error.new("invalid_client_metadata", "El cliente tiene que ser público.")
    end

    def self.lista(valor, default)
      return default if valor.nil?
      raise Error.new("invalid_client_metadata", "La metadata del cliente no es válida.") unless valor.is_a?(Array) && valor.all? { |item| item.is_a?(String) }

      valor
    end

    private_class_method :lista_de_uris, :uris_validas?, :exigir_publico!, :lista
  end
end
