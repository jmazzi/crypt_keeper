require 'spec_helper'

module CryptKeeper::LogSubscriber
  describe PostgresPgpPubKey do
    use_postgres

    # load key pairs from YAML
    keys_file   = YAML.load_file SPEC_ROOT.join('support/pgp_keys.yml')

    public_key  = keys_file['without_password']['public_key']
    private_key = keys_file['without_password']['private_key']
    test_data   = Base64.strict_decode64(keys_file['test_data'])

    subject { ::ActiveRecord::LogSubscriber.new }

    let(:input_query) do
      "SELECT pgp_pub_encrypt('hello', #{public_key}), pgp_pub_decrypt(#{test_data}, #{private_key}) FROM DUAL;"
    end

    let(:output_query) do
      "SELECT pgp_pub_encrypt([FILTERED]), pgp_pub_decrypt([FILTERED]) FROM DUAL;"
    end

    it "filters pgp functions" do
      subject.should_receive(:sql_without_postgres_pgp) do |event|
        event.payload[:sql].should == output_query
      end

      subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: output_query }))
    end
  end
end
