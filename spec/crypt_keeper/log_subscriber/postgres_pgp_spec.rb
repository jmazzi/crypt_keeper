require 'spec_helper'

describe CryptKeeper::LogSubscriber::PostgresPgp do
  let(:io) { StringIO.new }

  around do |example|
    CryptKeeper.silence_logs = false
    original_logger = ActiveRecord::Base.logger

    ActiveRecord::Base.logger = Logger.new(io)
    example.run
    ActiveRecord::Base.logger = original_logger
  end

  use_postgres

  context "Symmetric encryption" do
    subject { CryptKeeper::Provider::PostgresPgp.new key: ENCRYPTION_PASSWORD }

    it "sets log" do
      subject.encrypt("TEXT")
      puts io.string.split("\n")
    end
  end

  context "Symmetric encryption" do
    # Fire the ActiveSupport.on_load
    before do
      CryptKeeper::Provider::PostgresPgp.new key: 'secret'
    end

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
      should_log_scrubbed_query(input: input_query, output: output_query)
    end

    it "filters pgp functions in lowercase" do
      should_log_scrubbed_query(input: input_query.downcase, output: output_query.downcase.gsub(/filtered/, 'FILTERED'))
    end

    it "filters pgp functions when searching" do
      should_log_scrubbed_query(input: input_search_query, output: output_search_query)
    end

    it "forces string encodings" do
      input_query = "SELECT pgp_sym_encrypt('hi \255', 'test') FROM DUAL;"

      should_log_scrubbed_query(input: input_query, output: output_query)
    end

    it "skips logging if CryptKeeper.silence_logs is set" do
      CryptKeeper.silence_logs = true

      should_not_log_query(input_query)
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

    let(:input_query) do
      "SELECT pgp_pub_encrypt('test', dearmor('#{public_key}
      '))"
    end

    let(:output_query) do
      "SELECT encrypt([FILTERED])"
    end

    it "filters pgp functions" do
      should_log_scrubbed_query(input: input_query, output: output_query)
    end

    it "filters pgp functions in lowercase" do
      should_log_scrubbed_query(input: input_query.downcase, output: output_query.downcase.gsub(/filtered/, 'FILTERED'))
    end

    it "skips logging if CryptKeeper.silence_logs is set" do
      CryptKeeper.silence_logs = true

      should_not_log_query(input_query)
    end
  end
end
