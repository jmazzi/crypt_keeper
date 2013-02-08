unless RUBY_VERSION == '1.9.2'
  require 'mongoid'
  require 'logger'

  ::Mongoid.logger = Logger.new SPEC_ROOT.join('debug.log').to_s

  module CryptKeeper
    class SensitiveMongo
      include Mongoid::Document
      include CryptKeeper::Model

      field :storage, type: String
      field :secret, type: String
      field :name, type: Integer
    end

    module MongoidConnectionHelper
      def use_mongoid
        before :all do
          config = YAML.load_file SPEC_ROOT.join('database.yml')
          ::Mongoid::Config.load_configuration(config['mongoid'])
        end
      end
    end
  end


  RSpec.configure do |config|
    config.extend CryptKeeper::MongoidConnectionHelper
  end
end
