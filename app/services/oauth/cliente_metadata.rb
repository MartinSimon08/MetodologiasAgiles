require "ipaddr"
require "json"
require "net/http"
require "openssl"
require "resolv"
require "uri"

module Oauth
  class ClienteMetadata
    CACHE = 1.hour
    MAXIMO = 16 * 1024
    HOSTS_BLOQUEADOS = %w[metadata.google.internal metadata.google.com].freeze

    def self.call(url)
      return unless url_valida?(url)

      fila = OauthCliente.find_by(client_id: url, origen: "metadata")
      return cliente_de(fila) if fila&.metadata_expira_en&.future?

      documento = descargar(URI(url))
      return unless documento_valido?(documento, url)

      fila = OauthCliente.find_or_initialize_by(client_id: url)
      fila.update!(
        nombre: documento["client_name"].to_s.strip,
        redirect_uris: documento["redirect_uris"],
        origen: "metadata",
        metadata_expira_en: CACHE.from_now
      )
      cliente_de(fila)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      nil
    end

    def self.url_valida?(url)
      uri = URI.parse(url.to_s)
      return false unless uri.is_a?(URI::HTTPS)
      return false if uri.user.present? || uri.password.present? || uri.fragment.present? || uri.query.present?
      return false if uri.path.blank? || uri.path == "/"

      host = uri.host.to_s.downcase
      return false if host.blank? || HOSTS_BLOQUEADOS.include?(host)
      return false unless direcciones_publicas?(host)

      true
    rescue URI::InvalidURIError, Resolv::ResolvError
      false
    end

    def self.descargar(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 2
      http.read_timeout = 2
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      pedido = Net::HTTP::Get.new(uri)
      pedido["Accept"] = "application/json"
      respuesta = http.request(pedido)
      return unless respuesta.is_a?(Net::HTTPSuccess)

      cuerpo = respuesta.body.to_s.dup.force_encoding(Encoding::UTF_8)
      return unless cuerpo.valid_encoding? && cuerpo.bytesize <= MAXIMO

      JSON.parse(cuerpo)
    rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, IOError, JSON::ParserError
      nil
    end

    def self.documento_valido?(documento, url)
      return false unless documento.is_a?(Hash)
      return false unless documento["client_id"] == url
      return false if documento["client_name"].to_s.strip.blank?
      return false if documento["token_endpoint_auth_method"].present? && documento["token_endpoint_auth_method"] != "none"

      uris = documento["redirect_uris"]
      uris.is_a?(Array) && uris.size.between?(1, 5) && uris.all? { |uri| RedirectUri.permitida?(uri) }
    end

    def self.direcciones_publicas?(host)
      if ip?(host)
        return RedirectUri.direccion_publica?(host)
      end

      direcciones = Resolv.getaddresses(host)
      direcciones.present? && direcciones.all? { |direccion| RedirectUri.direccion_publica?(direccion) }
    end

    def self.ip?(host)
      IPAddr.new(host)
      true
    rescue IPAddr::InvalidAddressError
      false
    end

    def self.cliente_de(fila)
      ClienteResolver::Cliente.new(fila.client_id, fila.nombre, fila.redirect_uris)
    end

    private_class_method :url_valida?, :descargar, :documento_valido?, :direcciones_publicas?, :ip?, :cliente_de
  end
end
