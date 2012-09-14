require 'spec_helper'

module CryptKeeper
  module Provider
    describe PostgresPgpPubKey do
      use_postgres

      # load public and private keys from YAML
      keys_file     = YAML.load_file SPEC_ROOT.join('support/pgp_keys.yml')

      public_key    = keys_file['public_key']
      private_key   = keys_file['private_key']

      # the private key is protected by a password
      password      = keys_file['password']
      bad_password  = password.sub(/[aeiou]/, 'z')

      # cipher text varies in each encryption run
      cipher_text   = nil

      let(:plain_text)  { 'test' }

      subject { PostgresPgpPubKey.new public_key:   public_key,
                                      private_key:  private_key,
                                      password:     password }

      its(:public_key)  { should == public_key  }

      its(:private_key) { should == private_key }

      its(:password)    { should == password    }

      describe "#initialize" do
        it "should raise an exception with a missing :public_key" do
          expect { PostgresPgpPubKey.new }.to raise_error(ArgumentError, "Missing :public_key")
        end

        it "should raise an exception with a missing :private_key when :password is present" do
          expect { PostgresPgpPubKey.new  public_key: public_key,
                                          password:   password }.to raise_error(ArgumentError, "Provided :password but missing :private_key")
        end
      end

      describe "#encrypt" do
        it "should encrypt the string" do
          cipher_text = subject.encrypt(plain_text)

          cipher_text.should_not == plain_text
          cipher_text.should_not be_empty
        end
      end

      describe "#decrypt" do
        it "should decrypt the string" do
          subject.decrypt(cipher_text).should == plain_text
        end

        it "should return encrypted string when no :private_key is present" do
          crypt_only_subject = PostgresPgpPubKey.new public_key: public_key
          cipher_payload = crypt_only_subject.encrypt(plain_text)
          crypt_only_subject.decrypt(cipher_payload).should == cipher_payload
        end

        it "should return an error if an incorrect password is used" do
          subject.password = bad_password
          expect { subject.decrypt(cipher_text) }.to raise_error(ActiveRecord::StatementInvalid)
        end
      end
    end
  end
end
