require "ipaddr"
require "uri"

module Oauth
  module RedirectUri
    CURSOR = "cursor://anysphere.cursor-mcp/oauth/callback"
    LOOPBACK = %w[localhost 127.0.0.1 ::1].freeze

    def self.permitida?(valor)
      return false unless valor.is_a?(String)
      return false if valor.length > 500 || valor.match?(/[[:cntrl:]]/)
      return true if valor == CURSOR

      uri = URI.parse(valor)
      return false unless uri.is_a?(URI::HTTP)
      return false if uri.fragment.present? || uri.query.present? || uri.user.present? || uri.password.present?

      host = uri.host.to_s.downcase
      return false if host.blank?

      loopback?(host) || (uri.scheme == "https" && host_publico?(host))
    rescue URI::InvalidURIError
      false
    end

    def self.direccion_publica?(host)
      host_publico?(host)
    end

    def self.loopback?(host)
      LOOPBACK.include?(host.to_s.downcase)
    end

    def self.host_publico?(host)
      ip = IPAddr.new(host)
      return false if ip.loopback? || ip.private? || ip.link_local?
      return false if ip.ipv4? && (IPAddr.new("0.0.0.0/8").include?(ip) || IPAddr.new("224.0.0.0/4").include?(ip))
      return false if ip.ipv6? && IPAddr.new("ff00::/8").include?(ip)

      true
    rescue IPAddr::InvalidAddressError
      host != "localhost" && !host.end_with?(".localhost", ".local", ".internal")
    end

    private_class_method :host_publico?
  end
end
