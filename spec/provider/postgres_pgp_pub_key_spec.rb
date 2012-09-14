require 'spec_helper'

module CryptKeeper
  module Provider
    describe PostgresPgpPubKey do
      use_postgres

      # load key pairs from YAML
      keys_file     = YAML.load_file SPEC_ROOT.join('support/pgp_keys.yml')

      # password-protected keys
      pass_hash           = keys_file['with_password']
      pass_options        = { public_key:   pass_hash['public_key'],
                              private_key:  pass_hash['private_key'],
                              password:     pass_hash['password'] }
      pass_provider       = PostgresPgpPubKey.new pass_options

      # non-password-protected keys
      nopass_hash         = keys_file['without_password']
      nopass_options      = { public_key:   nopass_hash['public_key'],
                              private_key:  nopass_hash['private_key'] }
      nopass_provider     = PostgresPgpPubKey.new nopass_options

      # sample data to be encrypted/decrypted
      plain_text          = 'test'

      # cipher text varies in each encryption run
      cipher_text         = { pass: nil, nopass: nil }

      describe "#initialize" do
        describe "password-protected key pairs" do
          subject { pass_provider }

          its(:public_key)  { should == pass_hash['public_key'] }

          its(:private_key) { should == pass_hash['private_key'] }

          its(:password)    { should == pass_hash['password'] }
        end

        describe "non-password-protected key pairs" do
          subject { nopass_provider }

          its(:public_key)  { should == nopass_hash['public_key'] }

          its(:private_key) { should == nopass_hash['private_key'] }

          its(:password)    { should == nil }
        end

        context "malformed initialization options" do
          it "should raise an exception with a missing :public_key" do
            expect { PostgresPgpPubKey.new }.to raise_error(ArgumentError, "Missing :public_key")
          end

          it "should raise an exception with a missing :private_key when :password is present" do
            expect { PostgresPgpPubKey.new  public_key: pass_hash['public_key'],
                                            password:   pass_hash['password'] }.to raise_error(ArgumentError, "Provided :password but missing :private_key")
          end
        end
      end

      describe "#encrypt" do
        describe "password-protected key pairs" do
          subject { pass_provider }

          it "should encrypt" do
            cipher_text[:pass] = subject.encrypt(plain_text)
            cipher_text[:pass].should_not == plain_text
            cipher_text[:pass].should_not be_empty
          end
        end

        describe "non-password-protected key pairs" do
          subject { nopass_provider }

          it "should encrypt" do
            cipher_text[:nopass] = subject.encrypt(plain_text)
            cipher_text[:nopass].should_not == plain_text
            cipher_text[:nopass].should_not be_empty
          end
        end
      end

      describe "#decrypt" do
        describe "password-protected key pairs" do
          subject { pass_provider }

          it "should decrypt" do
            subject.decrypt(cipher_text[:pass]).should == plain_text
          end

          it "should return an error if an incorrect password is used" do
            subject.password = 'bad password'
            expect { subject.decrypt(cipher_text[:pass]) }.to raise_error(ActiveRecord::StatementInvalid)
          end
        end

        describe "non-password-protected key pairs" do
          subject { nopass_provider }

          it "should decrypt" do
            subject.decrypt(cipher_text[:nopass]).should == plain_text
          end
        end

        describe "pass-through decryption mode" do
          subject { PostgresPgpPubKey.new nopass_options }

          it "should return encrypted string when no :private_key is present" do
            subject.private_key = nil
            cipher_payload = subject.encrypt(plain_text)
            subject.decrypt(cipher_payload).should == cipher_payload
          end
        end
      end
    end
  end
end
