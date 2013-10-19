ENV['ARMOR_ITER'] ||= "10"
require 'coveralls'
Coveralls.wear!
require 'crypt_keeper'

SPEC_ROOT           = Pathname.new File.expand_path File.dirname __FILE__
AR_LOG              = SPEC_ROOT.join('debug.log').to_s
ENCRYPTION_PASSWORD = "supermadsecretstring"

Dir[SPEC_ROOT.join('support/*.rb')].each{|f| require f }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.after :each do
    ActiveRecord::Base.descendants.each do |model|
      model.method(:delete_all).call
    end
  end

  config.after :suite do
    if File.exist?(AR_LOG) && ENV['TRAVIS'].present?
      `grep \"#{ENCRYPTION_PASSWORD}\" #{AR_LOG}`

      if $?.exitstatus == 0
        raise StandardError, "\n\nERROR: The encryption password was found in the logs\n\n"
      end
    end
  end
end
