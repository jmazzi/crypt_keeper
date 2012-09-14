require 'spec_helper'

module CryptKeeper::LogSubscriber
  describe MysqlAes do
    use_postgres

    subject { ::ActiveRecord::LogSubscriber.new }

    let(:input_query) do
      "SELECT AES_ENCRYPT('encrypt_value', 'encrypt_key'), AES_ENCRYPT('decrypt_value', 'decrypt_key') FROM DUAL;"
    end

    let(:output_query) do
      "SELECT AES_ENCRYPT([FILTERED]), AES_DECRYPT([FILTERED]) FROM DUAL;"
    end

    it "filters mysql aes functions" do
      subject.should_receive(:sql_without_mysql_aes) do |event|
        event.payload[:sql].should == output_query
      end

      subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: output_query }))
    end
  end
end
