require 'spec_helper'

module CryptKeeper::LogSubscriber
  describe PostgresPgp do
    use_postgres

    # Fire the ActiveSupport.on_load
    before do
      CryptKeeper::Provider::PostgresPgp.new key: 'secret'
    end

    subject { ::ActiveRecord::LogSubscriber.new }

    let(:input_query) do
      "SELECT CASE 'encrypt_value' WHEN pgp_sym_encrypt('encrypt_value', 'encrypt_key') END, pgp_sym_decrypt('decrypt_value', 'decrypt_key') FROM DUAL;"
    end

    let(:output_query) do
      "SELECT CASE [FILTERED] WHEN pgp_sym_encrypt([FILTERED]) END, pgp_sym_decrypt([FILTERED]) FROM DUAL;"
    end

    it "filters pgp functions" do
      subject.should_receive(:sql_without_postgres_pgp) do |event|
        event.payload[:sql].should == output_query
      end

      subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query }))
    end
  end
end
