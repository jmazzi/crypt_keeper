require 'digest/sha1'
require 'openssl'
require 'base64'

module CryptKeeper
  module Encryptor
    class Aes
      attr_accessor :key, :aes

      def initialize(key)
        @aes         = ::OpenSSL::Cipher::Cipher.new("AES-256-CBC")
        @aes.padding = 1
        @key         = Digest::SHA1.hexdigest(key).unpack('a2'*32).map{|x|x.hex}.pack('c'*32)
      end

      def encrypt(value)
        value = value.to_s
        aes.encrypt
        aes.key = key
        Base64::encode64(aes.update(value) + aes.final)
      end

      def decrypt(value)
        value = Base64::decode64(value.to_s)
        aes.decrypt
        aes.key = key
        aes.update(value) + aes.final
      end

    end
  end
end
