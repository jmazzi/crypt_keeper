require 'spec_helper'

module CryptKeeper::LogSubscriber
  describe MysqlAes do
    use_mysql

    def test_filtering(input_query, output_query)
      subject.should_receive(:sql_without_mysql_aes) do |event|
        event.payload[:sql].should == output_query
      end

      subject.sql(ActiveSupport::Notifications::Event.new(:sql, 1, 1, 1, { sql: input_query }))
    end

    before do
      CryptKeeper::Provider::MysqlAesNew.new key: 'secret', salt: 'salt'
    end

    subject { ::ActiveRecord::LogSubscriber.new }

    let(:input_query_decrypt) do
      "SELECT AES_DECRYPT('ascii_value', 'encrypt_key');"
    end
    let(:output_query_decrypt) do
      "SELECT AES_DECRYPT([FILTERED]);"
    end

    let(:input_query_binary_decrypt) do
      binary_data = Base64.decode64("nbKOoWn8kvAw9k/C2Mex6Q==\n")
      "SELECT AES_DECRYPT('#{binary_data}', 'encrypt_key');"
    end
    let(:output_query_binary_decrypt) do
      "SELECT AES_DECRYPT([FILTERED]);"
    end

    let(:input_query_encrypt) do
      "INSERT INTO some_table (some_column) VALUES (AES_ENCRYPT('plaintext_value', 'encrypt_key'));"
    end
    let(:output_query_encrypt) do
      "INSERT INTO some_table (some_column) VALUES (AES_ENCRYPT([FILTERED]));"
    end

    let(:input_query_decrypt_base64) do
      "SELECT AES_DECRYPT(FROM_BASE64('base64_value'), 'encrypt_key') FROM some_table;"
    end
    let(:output_query_decrypt_base64) do
      "SELECT AES_DECRYPT([FILTERED]) FROM some_table;"
    end

    it "filters mysql decrypt function" do
      test_filtering input_query_decrypt, output_query_decrypt
    end

    it "filters mysql decrypt function for binary data when" do
      test_filtering input_query_binary_decrypt, output_query_binary_decrypt
    end

    it "filters mysql decrypt function in lower case" do
      output_query = output_query_decrypt.downcase.gsub(/filtered/, 'FILTERED')
      test_filtering input_query_decrypt.downcase, output_query
    end

    it "filters mysql encrypt function" do
      test_filtering input_query_encrypt, output_query_encrypt
    end

    it "filters mysql encrypt function in lower case" do
      output_query = output_query_encrypt.downcase.gsub(/filtered/, 'FILTERED')
      test_filtering input_query_encrypt.downcase, output_query
    end

    it "filters mysql decrypt used in combination with base64 decoding" do
      test_filtering input_query_decrypt_base64, output_query_decrypt_base64
    end
  end
end
