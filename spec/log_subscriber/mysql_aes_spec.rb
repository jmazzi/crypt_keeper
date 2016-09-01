require 'spec_helper'

module CryptKeeper::LogSubscriber
  describe MysqlAes do
    before do
      CryptKeeper.silence_logs = false
    end

    use_mysql

    context "AES encryption" do
      # Fire the ActiveSupport.on_load
      before do
        CryptKeeper::Provider::MysqlAesNew.new key: 'secret', salt: 'salt'
      end

      subject { ::ActiveRecord::LogSubscriber.new }

      let(:input_query) do
        "SELECT aes_encrypt('encrypt_value', 'encrypt_key'), aes_decrypt('decrypt_value', 'decrypt_key') FROM DUAL;"
      end

      let(:output_query) do
        "SELECT aes_encrypt([FILTERED]) FROM DUAL;"
      end

      let(:input_search_query) do
        "SELECT \"sensitive_data\".* FROM \"sensitive_data\" WHERE ((aes_decrypt('f'), 'tool') = 'blah')) AND secret = 'testing'"
      end

      let(:output_search_query) do
        "SELECT \"sensitive_data\".* FROM \"sensitive_data\" WHERE ((aes_decrypt([FILTERED]) AND secret = 'testing'"
      end

      it "filters aes functions" do
        subject.should_receive(:sql_without_mysql_aes) do |event|
          event.payload[:sql].should == output_query
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query }))
      end

      it "filters aes functions in lowercase" do
        subject.should_receive(:sql_without_mysql_aes) do |event|
          event.payload[:sql].should == output_query.downcase.gsub(/filtered/, 'FILTERED')
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query.downcase }))
      end

      it "filters aes functions when searching" do
        subject.should_receive(:sql_without_mysql_aes) do |event|
          event.payload[:sql].should == output_search_query
        end

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_search_query }))
      end

      it "forces string encodings" do
        string_encoding_query = "SELECT aes_encrypt('hi \255', 'test')"
        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: string_encoding_query }))
      end

      it "skips logging if CryptKeeper.silence_logs is set" do
        CryptKeeper.silence_logs = true

        subject.should_not_receive(:sql_without_mysql_aes)

        subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query }))
      end
    end
  end
end
