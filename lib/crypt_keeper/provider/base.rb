module CryptKeeper
  module Provider
    class Base
      def dump(value)
        if value.blank? || CryptKeeper.stub_encryption?
          value
        else
          encrypt(value.to_s)
        end
      end

      def load(value)
        if value.blank? || CryptKeeper.stub_encryption?
          value
        else
          decrypt(value)
        end
      end
    end
  end
end
