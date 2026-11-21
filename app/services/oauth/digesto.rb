require "digest"

module Oauth
  module Digesto
    def self.de(valor)
      Digest::SHA256.hexdigest(valor.to_s)
    end
  end
end
