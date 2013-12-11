require 'spec_helper'

module CryptKeeper
  module Provider
    describe PostgresPgp do
      use_postgres

      def self.read_key(file)
        IO.read(File.join(SPEC_ROOT, 'fixtures', file))
      end

      let(:cipher_text) { '\xc30d04070302f1a092093988b26873d235017203ce086a53fce1925dc39b4e972e534f192d10b94af3dcf8589abc1f828456f5d3e20b225d56006ffd1e312e3b8a492a6010e9' }
      let(:plain_text)  { 'test' }

      let(:integer_cipher_text) { '\xc30d04070302c8d266353bcf2fc07dd23201153f9d9c32fbb3c36b9b0db137bf8b6c609172210d89ded63f11dff23d1ddbf5111c0266549dde26175c4425e06bb4bd6f' }

      let(:integer_plain_text) { 1 }

      let(:public_key) do
        IO.read(File.join(SPEC_ROOT, 'fixtures', 'public.asc'))
      end

      let(:private_key) do
        IO.read(File.join(SPEC_ROOT, 'fixtures', 'private.asc'))
      end

      let(:private_key_passphrase) { 'crypt_keeper' }

      subject { PostgresPgp.new key: ENCRYPTION_PASSWORD }

      its(:key) { should == ENCRYPTION_PASSWORD }

      describe "#initialize" do
        specify { expect { PostgresPgp.new }.to raise_error(ArgumentError, "Missing :key") }
      end

      describe "#encrypt" do
        context "Strings" do
          specify { subject.encrypt(plain_text).should_not == plain_text }
          specify { subject.encrypt(plain_text).should_not be_empty }
        end

        context "Integers" do
          specify { subject.encrypt(integer_plain_text).should_not == integer_plain_text }
          specify { subject.encrypt(integer_plain_text).should_not be_empty }
        end
      end

      describe "#decrypt" do
        specify { subject.decrypt(cipher_text).should == plain_text }
        specify { subject.decrypt(integer_cipher_text).should == integer_plain_text.to_s }
      end

      describe "#search" do
        it "finds the matching record" do
          SensitiveDataPg.create!(storage: 'blah2')
          match = SensitiveDataPg.create!(storage: 'blah')
          SensitiveDataPg.search_by_plaintext(:storage, 'blah').first.should == match
        end
      end

      describe "Custom pgcrypto options" do
        let(:pgcrypto_options) { 'compress-level=0' }

        subject { PostgresPgp.new key: 'candy', pgcrypto_options: pgcrypto_options }

        it "reads and writes" do
          queries = logged_queries do
            encrypted = subject.encrypt(plain_text)
            subject.decrypt(encrypted).should == plain_text
          end

          queries.should_not be_empty

          queries.select { |query| query.include?("pgp_sym_encrypt") }.each do |q|
            q.should include(pgcrypto_options)
          end
        end
      end

      context "Public key encryption" do
        let(:cipher_text) { '\xc1c04c036c401ad086beb9e3010800987d6c4ccd974322190caa75a3a01aba37bc1970182c4c1d3faec98edf186780520f0586101f286e0626096a1eca91a229ed4d4058a6913a8d13cdf49f29ea44e2b96d10347f9b1b860bb3c959f000a3b1b415a95d2cd07af8c74aa6df8cd10ab06b6a6f7db69cdf3185466d68c5b66b95b813acdfb3ddfb021cac92e0967d67e90df73332f27970c1d2b9a56ac74f602d4107b163ed73ef89fca560d9a0a0d2bc7a74005f29fa27babfbaf950ac07b1c809049db4ab126be4824cf76416c278571f7064f638edf830a1ae5ee1ab544d35fce0f974f21b9dcbbea3986077d27b0de34144dc23f369f471090b57e067a056901e680493ddf2a6b29e4af3462387d235010259556079d07daa249b6703e2bc79345da556cfb46f228cad40a8a5b569ac46f08865f9176acf89129a3e0ceb2a7b1991012f65' }

        let(:integer_cipher_text) { '\xc1c04c036c401ad086beb9e30107ff59e674ba05958eb053c2427b44355e0f333f1726e18a0b851130130510c648f580b13b3f6a223eb26e397008596867c5a511a4f5bfbf2ecc852d8929814480d63166e525fa2b259b6a8d4474b5b1373b4e1a4fe70a491d25442e1c0046fd3d69466ad30153c8d8d920e9b4260d4e4e421ef3ead162b3aba5d85408c4ef9f9d342b5655c7568d1bdc61c27ddb419133bf091f22f42e7bc91ec6d279b7b25b87ea65119568b85ae81079dd0a6a7258b58fb219c6cc4580f33cb46de97770a1eb0880bdf87426fd0529576a1e791e521d9b3c426e393e63d83321f319b00f9dc4027ea5a81dd57c0f5ba868fb86d73179c34f2287c437266e8becc072b45a929562d2320194be54464e03854635d0f7d7fb10813adbc6efe51efa9095a9bacc2a03fb5c41d1c1896384e4f36b100c0f00e81d4cff7d' }

        subject { PostgresPgp.new key: ENCRYPTION_PASSWORD, public_key: public_key, private_key: private_key }

        describe "#encrypt" do
          context "Missing private key" do
            it "does not decrypt" do
              pgp = PostgresPgp.new key: ENCRYPTION_PASSWORD, public_key: public_key
              pgp.decrypt(cipher_text).should be_nil
            end
          end

          context "Strings" do
            specify { subject.encrypt(plain_text).should_not == plain_text }
            specify { subject.encrypt(plain_text).should_not be_empty }
          end

          context "Integers" do
            specify { subject.encrypt(integer_plain_text).should_not == integer_plain_text }
            specify { subject.encrypt(integer_plain_text).should_not be_empty }
          end
        end

        describe "#decrypt" do
          specify { subject.decrypt(cipher_text).should == plain_text }
          specify { subject.decrypt(integer_cipher_text).should == integer_plain_text.to_s }
        end
      end
    end
  end
end
