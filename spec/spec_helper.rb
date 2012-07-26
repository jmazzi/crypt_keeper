require 'crypt_keeper'

SPEC_ROOT = Pathname.new File.expand_path File.dirname __FILE__
Dir[SPEC_ROOT.join('support/*.rb')].each{|f| require f }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end
