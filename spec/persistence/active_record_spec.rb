require 'spec_helper'

module CryptKeeper
  module Persistence
    describe ActiveRecord do
      use_sqlite

      subject { SensitiveData }

      describe "#crypt_keeper" do
        after(:each) do
          subject.instance_variable_set(:@encryptor_klass, nil)
          subject.instance_variable_set(:@encryptor, nil)
        end

        context "Fields" do
          it "enables encryption for the given fields" do
            subject.crypt_keeper :storage, :secret, encryptor: :fake_encryptor
            subject.crypt_keeper_fields.should == [:storage, :secret]
          end

          it "raises an exception for missing field" do
            msg = "Column :none does not exist"
            subject.crypt_keeper :none, encryptor: :fake_encryptor
            expect { subject.new.save }.to raise_error(ArgumentError, msg)
          end

          it "raises an exception for non text fields" do
            msg = "Column :name must be of type 'text' to be used for encryption"
            subject.crypt_keeper :name, encryptor: :fake_encryptor
            expect { subject.new.save }.to raise_error(ArgumentError, msg)
          end
        end
      end
    end
  end
end
