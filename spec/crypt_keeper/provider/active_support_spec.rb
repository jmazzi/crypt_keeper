require 'spec_helper'

describe CryptKeeper::Provider::ActiveSupport do
  subject { described_class.new(key: 'cake', salt: 'salt') }

  let :plaintext do
    "string"
  end

  let :encrypted do
    subject.encrypt plaintext
  end

  let :decrypted do
    subject.decrypt encrypted
  end

  describe "#encrypt" do
    specify { expect(encrypted).to_not eq(plaintext) }
    specify { expect(encrypted).to_not be_blank }
  end

  describe "#decrypt" do
    specify { expect(decrypted).to eq(plaintext) }
    specify { expect(decrypted).to_not be_blank }
  end

  describe "#search" do
    let :records do
      [{ name: 'Bob' }, { name: 'Tim' }]
    end

    it "finds the matching record" do
      expect(subject.search(records, :name, 'Bob')).to eql([records.first])
    end
  end
end
