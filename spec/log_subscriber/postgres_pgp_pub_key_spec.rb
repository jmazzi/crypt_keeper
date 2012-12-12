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

    # pgp_pub_encrypt

    it "filters pgp_pub_encrypt function" do
      iq = "SELECT pgp_pub_encrypt('hello', dearmor(#{public_key}))"
      oq = "SELECT pgp_pub_encrypt([FILTERED])"

      execute_sql(iq, oq)
    end

    # pgp_pub_decrypt

    it "filters pgp_pub_decrypt function" do
      iq = "SELECT pgp_pub_decrypt(#{test_data}, dearmor(#{private_key}));"
      oq = "SELECT pgp_pub_decrypt([FILTERED])"

      execute_sql(iq, oq)
    end

    # stacked pgp functions

    it "filters stacked pgp functions" do
      iq = "SELECT pgp_pub_encrypt('hello', dearmor(#{public_key})), pgp_pub_decrypt(#{test_data}, dearmor(#{private_key})) FROM DUAL;"
      oq = "SELECT pgp_pub_encrypt([FILTERED])"

      execute_sql(iq, oq)
    end

    # key_id functions

    it "filters pgp_key_id functions" do
      # public_key_id
      iq = "SELECT pgp_key_id(dearmor(#{public_key}));"
      oq = "SELECT pgp_key_id([FILTERED])"

      execute_sql(iq, oq)

      # private_key_id
      iq = "SELECT pgp_key_id(dearmor(#{private_key}));"
      oq = "SELECT pgp_key_id([FILTERED])"

      execute_sql(iq, oq)
    end

    private

    def execute_sql(query_in, query_out)
      subject.should_receive(:sql_without_postgres_pgp_pub_key) do |event|
        event.payload[:sql].should == query_out
      end

      subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: query_in }))
    end
  end
end
