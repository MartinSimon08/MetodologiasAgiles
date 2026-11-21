require "base64"
require "digest"

module Oauth
  class EmitirToken
    def self.call(params:, recurso:)
      case params[:grant_type]
      when "authorization_code" then por_codigo(params, recurso)
      when "refresh_token" then por_refresh(params, recurso)
      else
        raise Error.new("unsupported_grant_type", "El grant no está soportado.")
      end
    end

    def self.por_codigo(params, recurso)
      cliente = cliente!(params[:client_id])
      exigir_presentes!(params, %i[code redirect_uri code_verifier resource])
      exigir_recurso!(params[:resource], recurso)
      codigo = OauthCodigo.find_by(digesto: Digesto.de(params[:code]))
      raise invalido_codigo unless codigo&.client_id == cliente.client_id

      resultado = codigo.with_lock do
        raise invalido_codigo if codigo.usado_en || codigo.expira_en.past?
        raise invalido_codigo unless codigo.redirect_uri == params[:redirect_uri]
        raise invalido_codigo unless ClienteResolver.acepta?(cliente, codigo.redirect_uri)
        raise Error.new("invalid_target", "El recurso no coincide con este taller.") unless Recurso.iguales?(codigo.recurso, recurso.mcp)

        codigo.update!(usado_en: Time.current)
        next :invalido unless verificador_valido?(params[:code_verifier], codigo.code_challenge)

        crear_par(codigo.usuario, cliente.client_id, recurso)
      end
      raise invalido_codigo if resultado == :invalido

      resultado
    end

    def self.por_refresh(params, recurso)
      cliente = cliente!(params[:client_id])
      exigir_presentes!(params, %i[refresh_token resource])
      exigir_recurso!(params[:resource], recurso)
      token = OauthRefreshToken.find_by(digesto: Digesto.de(params[:refresh_token]))
      raise invalido_refresh unless token&.client_id == cliente.client_id
      raise Error.new("invalid_target", "El recurso no coincide con este taller.") unless Recurso.iguales?(token.recurso, recurso.mcp)

      resultado = token.with_lock do
        if token.reemplazado_en || token.revocado_en
          OauthRefreshToken.where(familia: token.familia, revocado_en: nil).update_all(revocado_en: Time.current)
          next :invalido
        end
        next :invalido if token.expira_en.past? || !token.usuario.reload.activo?

        token.update!(reemplazado_en: Time.current)
        crear_par(token.usuario, cliente.client_id, recurso, token.familia)
      end
      raise invalido_refresh if resultado == :invalido

      resultado
    end

    def self.crear_par(usuario, client_id, recurso, familia = SecureRandom.uuid)
      crudo = SecureRandom.urlsafe_base64(32)
      OauthRefreshToken.create!(
        digesto: Digesto.de(crudo),
        familia: familia,
        usuario: usuario,
        client_id: client_id,
        recurso: recurso.mcp,
        scope: AccessToken::SCOPE,
        expira_en: OauthRefreshToken::TTL.from_now
      )
      {
        access_token: AccessToken.emitir(usuario: usuario, recurso: recurso, client_id: client_id),
        token_type: "Bearer",
        expires_in: AccessToken::TTL.to_i,
        refresh_token: crudo,
        scope: AccessToken::SCOPE
      }
    end

    def self.cliente!(client_id)
      ClienteResolver.call(client_id) || raise(Error.new("invalid_client", "Cliente desconocido.", http: :unauthorized))
    end

    def self.exigir_presentes!(params, claves)
      return if claves.all? { |clave| params[clave].present? }

      raise Error.new("invalid_request", "La solicitud está incompleta.")
    end

    def self.exigir_recurso!(valor, recurso)
      return if Recurso.iguales?(Recurso.canonico(valor), recurso.mcp)

      raise Error.new("invalid_target", "El recurso no coincide con este taller.")
    end

    def self.verificador_valido?(verificador, desafio)
      return false unless verificador.is_a?(String) && verificador.match?(/\A[A-Za-z0-9\-._~]{43,128}\z/)

      calculado = Base64.urlsafe_encode64(Digest::SHA256.digest(verificador), padding: false)
      Recurso.iguales?(calculado, desafio)
    end

    def self.invalido_codigo
      Error.new("invalid_grant", "El código no es válido.")
    end

    def self.invalido_refresh
      Error.new("invalid_grant", "El refresh token no es válido.")
    end

    private_class_method :por_codigo, :por_refresh, :crear_par, :cliente!, :exigir_presentes!, :exigir_recurso!,
      :verificador_valido?, :invalido_codigo, :invalido_refresh
  end
end
