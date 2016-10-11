require 'spec_helper'

describe CryptKeeper::Provider::PostgresPgpPublicKey do
  use_postgres

  let(:cipher_text) { '\xc1c04c036c401ad086beb9e3010800987d6c4ccd974322190caa75a3a01aba37bc1970182c4c1d3faec98edf186780520f0586101f286e0626096a1eca91a229ed4d4058a6913a8d13cdf49f29ea44e2b96d10347f9b1b860bb3c959f000a3b1b415a95d2cd07af8c74aa6df8cd10ab06b6a6f7db69cdf3185466d68c5b66b95b813acdfb3ddfb021cac92e0967d67e90df73332f27970c1d2b9a56ac74f602d4107b163ed73ef89fca560d9a0a0d2bc7a74005f29fa27babfbaf950ac07b1c809049db4ab126be4824cf76416c278571f7064f638edf830a1ae5ee1ab544d35fce0f974f21b9dcbbea3986077d27b0de34144dc23f369f471090b57e067a056901e680493ddf2a6b29e4af3462387d235010259556079d07daa249b6703e2bc79345da556cfb46f228cad40a8a5b569ac46f08865f9176acf89129a3e0ceb2a7b1991012f65' }

  let(:integer_cipher_text) { '\xc1c04c036c401ad086beb9e30107ff59e674ba05958eb053c2427b44355e0f333f1726e18a0b851130130510c648f580b13b3f6a223eb26e397008596867c5a511a4f5bfbf2ecc852d8929814480d63166e525fa2b259b6a8d4474b5b1373b4e1a4fe70a491d25442e1c0046fd3d69466ad30153c8d8d920e9b4260d4e4e421ef3ead162b3aba5d85408c4ef9f9d342b5655c7568d1bdc61c27ddb419133bf091f22f42e7bc91ec6d279b7b25b87ea65119568b85ae81079dd0a6a7258b58fb219c6cc4580f33cb46de97770a1eb0880bdf87426fd0529576a1e791e521d9b3c426e393e63d83321f319b00f9dc4027ea5a81dd57c0f5ba868fb86d73179c34f2287c437266e8becc072b45a929562d2320194be54464e03854635d0f7d7fb10813adbc6efe51efa9095a9bacc2a03fb5c41d1c1896384e4f36b100c0f00e81d4cff7d' }

  let(:integer_plain_text) { 1 }
  let(:plain_text)  { 'test' }

  let(:public_key) do
    IO.read(File.join(SPEC_ROOT, 'fixtures', 'public.asc'))
  end

  let(:private_key) do
    IO.read(File.join(SPEC_ROOT, 'fixtures', 'private.asc'))
  end

  subject { described_class.new key: ENCRYPTION_PASSWORD, public_key: public_key, private_key: private_key }


  specify { expect(subject.key).to eq(ENCRYPTION_PASSWORD) }

  describe "#initialize" do
    specify { expect { described_class.new }.to raise_error(ArgumentError, "Missing :key") }
  end

  describe "#encrypt" do
    context "Strings" do
      specify { expect(subject.encrypt(plain_text)).to_not eq(plain_text) }
      specify { expect(subject.encrypt(plain_text)).to_not be_empty }

      it "does not double encrypt" do
        pgp = described_class.new key: ENCRYPTION_PASSWORD, public_key: public_key
        expect(pgp.encrypt(cipher_text)).to eq(cipher_text)
      end
    end

    context "Integers" do
      specify { expect(subject.encrypt(integer_plain_text)).to_not eq(integer_plain_text) }
      specify { expect(subject.encrypt(integer_plain_text)).to_not be_empty }
    end
  end

  describe "#decrypt" do
    specify { expect(subject.decrypt(cipher_text)).to eq(plain_text) }
    specify { expect(subject.decrypt(integer_cipher_text)).to eq(integer_plain_text.to_s) }

    it "does not decrypt w/o private key" do
      pgp = described_class.new key: ENCRYPTION_PASSWORD, public_key: public_key
      expect(pgp.decrypt(cipher_text)).to eq(cipher_text)
    end
  end

  describe "#encrypted?" do
    it "returns true for encrypted strings" do
      expect(subject.encrypted?(cipher_text)).to be_truthy
    end

    it "returns false for non-encrypted strings" do
      expect(subject.encrypted?(plain_text)).to be_falsey
    end
  end
end
