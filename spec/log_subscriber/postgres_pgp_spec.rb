require 'spec_helper'

module CryptKeeper::LogSubscriber
  describe PostgresPgp do
    use_postgres

    context "Symmetric encryption" do
      # Fire the ActiveSupport.on_load
      before do
        CryptKeeper::Provider::PostgresPgp.new key: 'secret'
      end

      subject { ::ActiveRecord::LogSubscriber.new }

      let(:input_query) do
        "SELECT pgp_sym_encrypt('encrypt_value', 'encrypt_key'), pgp_sym_decrypt('decrypt_value', 'decrypt_key') FROM DUAL;"
      end

      let(:output_query) do
        "SELECT encrypt([FILTERED]) FROM DUAL;"
      end

      let(:input_search_query) do
        "SELECT \"sensitive_data\".* FROM \"sensitive_data\" WHERE ((pgp_sym_decrypt('f'), 'tool') = 'blah')) AND secret = 'testing'"
      end

      let(:output_search_query) do
        "SELECT \"sensitive_data\".* FROM \"sensitive_data\" WHERE decrypt([FILTERED]) AND secret = 'testing'"
      end

      it "filters pgp functions" do
        subject.should_receive(:sql_without_postgres_pgp) do |event|
          event.payload[:sql].should == output_query
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query }))
      end

      it "filters pgp functions in lowercase" do
        subject.should_receive(:sql_without_postgres_pgp) do |event|
          event.payload[:sql].should == output_query.downcase.gsub(/filtered/, 'FILTERED')
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query.downcase }))
      end

      it "filters pgp functions when searching" do
        subject.should_receive(:sql_without_postgres_pgp) do |event|
          event.payload[:sql].should == output_search_query
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_search_query }))
      end
    end

    context "Public key encryption" do
      let(:public_key) do
        IO.read(File.join(SPEC_ROOT, 'fixtures', 'public.asc'))
      end

      let(:private_key) do
        IO.read(File.join(SPEC_ROOT, 'fixtures', 'private.asc'))
      end

      # Fire the ActiveSupport.on_load
      before do
        CryptKeeper::Provider::PostgresPgpPublicKey.new key: 'secret', public_key: public_key, private_key: private_key
      end

      subject { ::ActiveRecord::LogSubscriber.new }

      let(:input_query) do
        "SELECT pgp_pub_encrypt('test', dearmor('#{public_key}
        '))"
      end

      let(:output_query) do
        "SELECT encrypt([FILTERED])"
      end

      it "filters pgp functions" do
        subject.should_receive(:sql_without_postgres_pgp) do |event|
          event.payload[:sql].should == output_query
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query }))
      end

      it "filters pgp functions in lowercase" do
        subject.should_receive(:sql_without_postgres_pgp) do |event|
          event.payload[:sql].should == output_query.downcase.gsub(/filtered/, 'FILTERED')
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query.downcase }))
      end
    end
  end
end
