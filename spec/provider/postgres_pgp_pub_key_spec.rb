require 'spec_helper'

module CryptKeeper
  module Provider
    describe PostgresPgpPubKey do
      use_postgres

      public_key = <<END_PUBLIC_KEY
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.12 (Darwin)

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
F7gvbyrgd6l23bhfZPUI
=yy3g
-----END PGP PUBLIC KEY BLOCK-----
END_PUBLIC_KEY

      private_key = <<END_PRIVATE_KEY
-----BEGIN PGP PRIVATE KEY BLOCK-----
Version: GnuPG v1.4.12 (Darwin)

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
=xsXd
-----END PGP PRIVATE KEY BLOCK-----
END_PRIVATE_KEY

      password      = 'DjcQTNE8OzbbvAvhPUNBbhKuexHDwOwEObDGlVqyrd9LxLAU'
      bad_password  = 'BjcQTNE8OzbbvAvhPUNBbhKuexHDwOwEObDGlVqyrd9LxLAU'
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
