require 'spec_helper'

describe CryptKeeper::LogSubscriber::PostgresPgp do
  before do
    CryptKeeper.silence_logs = false
  end

  use_postgres

  context "Symmetric encryption" do
    # Fire the ActiveSupport.on_load
    before do
      CryptKeeper::Provider::PostgresPgp.new key: 'secret'
    end

    let(:queries) {
      {
        "SELECT pgp_sym_encrypt('encrypt_value', 'encrypt_key') FROM DUAL;" => "SELECT pgp_sym_encrypt([FILTERED]) FROM DUAL;",
        "SELECT pgp_sym_decrypt('encrypt_value') FROM DUAL;" => "SELECT pgp_sym_decrypt([FILTERED]) FROM DUAL;",
        "SELECT pgp_key_id('encrypt_value') FROM DUAL;" => "SELECT pgp_key_id([FILTERED]) FROM DUAL;",
        "SELECT \"sensitive_data\".* FROM \"sensitive_data\" WHERE ((pgp_sym_decrypt('f'), 'tool') = 'blah')) AND secret = 'testing'" => "SELECT \"sensitive_data\".* FROM \"sensitive_data\" WHERE pgp_sym_decrypt([FILTERED]) AND secret = 'testing'",
      }
    }

    it "filters pgp functions" do
      queries.each do |k, v|
        should_log_scrubbed_query(input: k, output: v)
      end
    end

    it "filters pgp functions in lowercase" do
      queries.each do |k, v|
        should_log_scrubbed_query(input: k.downcase, output: v.downcase.gsub(/filtered/, 'FILTERED'))
      end
    end

    it "forces string encodings" do
      queries.each do |k, v|
        k = "#{k}\255"
        should_log_scrubbed_query(input: k, output: v)
      end
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

    let(:queries) {
      {
        "SELECT pgp_pub_encrypt('test', dearmor('#{public_key}')) FROM DUAL;" => "SELECT pgp_pub_encrypt([FILTERED]) FROM DUAL;",
        "SELECT pgp_pub_decrypt('test', dearmor('#{public_key}'), '#{private_key}') FROM DUAL;" => "SELECT pgp_pub_decrypt([FILTERED]) FROM DUAL;",
      }
    }

    it "filters pgp functions" do
      queries.each do |k, v|
        should_log_scrubbed_query(input: k, output: v)
      end
    end

    it "filters pgp functions in lowercase" do
      queries.each do |k, v|
        should_log_scrubbed_query(input: k.downcase, output: v.downcase.gsub(/filtered/, 'FILTERED'))
      end
    end
  end
end
