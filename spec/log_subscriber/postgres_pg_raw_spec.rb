require 'spec_helper'

module CryptKeeper::LogSubscriber
  describe PostgresRaw do
    use_postgres

    context "Without IV" do
      # Fire the ActiveSupport.on_load
      before do
        CryptKeeper::Provider::PostgresRaw.new key: 'secret'
      end

      subject { ::ActiveRecord::LogSubscriber.new }

      let(:input_query) do
        "SELECT encrypt('encrypt_value', 'encrypt_key', 'encrypt_option'), encode(decrypt('decrypt_value', 'decrypt_key', 'decrypt_option'), 'escape') FROM DUAL;"
      end

      let(:output_query) do
        "SELECT encrypt([FILTERED]) FROM DUAL;"
      end

      let(:input_search_query) do
        "SELECT \"sensitive_data\".* FROM \"sensitive_data\" WHERE encode(decrypt('decrypt_value', 'decrypt_key', 'decrypt_option'), 'escape') AND secret = 'testing'"
      end

      let(:output_search_query) do
        "SELECT \"sensitive_data\".* FROM \"sensitive_data\" WHERE decrypt([FILTERED]) AND secret = 'testing'"
      end

      it "filters pgp functions" do
        subject.should_receive(:sql_without_postgres_raw) do |event|
          event.payload[:sql].should == output_query
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query }))
      end

      it "filters pgp functions in lowercase" do
        subject.should_receive(:sql_without_postgres_raw) do |event|
          event.payload[:sql].should == output_query.downcase.gsub(/filtered/, 'FILTERED')
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query.downcase }))
      end

      it "filters pgp functions when searching" do
        subject.should_receive(:sql_without_postgres_raw) do |event|
          event.payload[:sql].should == output_search_query
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_search_query }))
      end

      it "forces string encodings" do
        string_encoding_query = "SELECT encrypt('hi \255', 'test', 'aes')"
        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: string_encoding_query }))
      end
    end

    context "With IV" do
      # Fire the ActiveSupport.on_load
      before do
        CryptKeeper::Provider::PostgresRaw.new key: 'secret'
      end

      subject { ::ActiveRecord::LogSubscriber.new }

      let(:input_query) do
        "SELECT encrypt_iv('encrypt_value', 'encrypt_key', 'encrypt_option'), encode(decrypt_iv('decrypt_value', 'decrypt_key', 'decrypt_option'), 'escape') FROM DUAL;"
      end

      let(:output_query) do
        "SELECT encrypt([FILTERED]) FROM DUAL;"
      end

      let(:input_search_query) do
        "SELECT \"sensitive_data\".* FROM \"sensitive_data\" WHERE encode(decrypt_iv('decrypt_value', 'decrypt_key', 'decrypt_option'), 'escape') AND secret = 'testing'"
      end

      let(:output_search_query) do
        "SELECT \"sensitive_data\".* FROM \"sensitive_data\" WHERE decrypt([FILTERED]) AND secret = 'testing'"
      end

      it "filters pgp functions" do
        subject.should_receive(:sql_without_postgres_raw) do |event|
          event.payload[:sql].should == output_query
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query }))
      end

      it "filters pgp functions in lowercase" do
        subject.should_receive(:sql_without_postgres_raw) do |event|
          event.payload[:sql].should == output_query.downcase.gsub(/filtered/, 'FILTERED')
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query.downcase }))
      end

      it "filters pgp functions when searching" do
        subject.should_receive(:sql_without_postgres_raw) do |event|
          event.payload[:sql].should == output_search_query
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_search_query }))
      end

      it "forces string encodings" do
        string_encoding_query = "SELECT encrypt('hi \255', 'test', 'aes')"
        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: string_encoding_query }))
      end
    end
  end
end
