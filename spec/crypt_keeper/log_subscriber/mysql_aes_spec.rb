require 'spec_helper'

describe CryptKeeper::LogSubscriber::MysqlAes do
  before do
    CryptKeeper.silence_logs = false
  end

  use_mysql

  context "AES encryption" do
    # Fire the ActiveSupport.on_load
    before do
      CryptKeeper::Provider::MysqlAesNew.new key: 'secret', salt: 'salt'
    end

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
      should_log_scrubbed_query(input: input_query, output: output_query)
    end

    it "filters aes functions in lowercase" do
      should_log_scrubbed_query(input: input_query.downcase, output: output_query.downcase.gsub(/filtered/, 'FILTERED'))
    end

    it "filters aes functions when searching" do
      should_log_scrubbed_query(input: input_search_query, output: output_search_query)
    end

    it "forces string encodings" do
      input_query = "SELECT aes_encrypt('hi \255', 'test') FROM DUAL;"

      should_log_scrubbed_query(input: input_query, output: output_query)
    end
  end
end
