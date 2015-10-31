require 'spec_helper'

module Logical
  module Naf

    describe UserSession do
      let!(:user_session) { ::Logical::Naf::UserSession.new(nil) }

      describe '#valid?' do
        it 'return false when message is not present' do
          expect(user_session.valid?).to be_falsey
        end

        it 'return false when value is not present' do
          user_session.instance_variable_set(:@message, {})
          expect(user_session.valid?).to be_falsey
        end

        it 'return false when session is expired' do
          user_session.instance_variable_set(:@message, { value: Time.zone.now - 1.month })
          expect(user_session.valid?).to be_falsey
        end

        it 'return true for invalid signed message' do
          user_session.instance_variable_set(:@message, { value: Time.zone.now - 1.hour })
          expect(user_session.valid?).to be_truthy
        end
      end

      describe '#token_cookie' do
        let!(:signed_message) { user_session.token_cookie }

        it 'not be nil' do
          expect(signed_message).not_to be_nil
        end
      end

      describe '#build_token_cookie' do
        before do
          Timecop.freeze(Time.zone.now)
        end

        after do
          Timecop.return
        end

        it 'return hash with current time' do
          expect(::Logical::Naf::UserSession.build_token_cookie).to eq({ value: Time.zone.now })
        end
      end

      describe '#sign_message' do
        it 'return nil when message is nil' do
          expect(::Logical::Naf::UserSession.sign_message(nil)).to be_nil
        end

        skip 'sign the message when message is present' do
          expect(::Logical::Naf::UserSession.sign_message(::Logical::Naf::UserSession.build_token_cookie)).
            to match(/^.{123}={1}-{2}[a-zA-Z0-9]{40}$/)
        end
      end

      describe '#unsign_message' do
        it 'return nil when message is not signed' do
          expect(::Logical::Naf::UserSession.unsign_message(nil)).to be_nil
        end

        it 'return nil when InvalidSignature exception is raised' do
          allow(::Logical::Naf::UserSession).to receive(:message_verifier).
            and_raise(ActiveSupport::MessageVerifier::InvalidSignature)
          expect(::Logical::Naf::UserSession.unsign_message(nil)).to be_nil
        end

        it 'return message when signed message is valid' do
          message_verifier = ActiveSupport::MessageVerifier.
            new(Rails.application.class.config.secret_token)
          message = { value: Time.zone.now }

          expect(::Logical::Naf::UserSession.
            unsign_message(message_verifier.generate(message))).to eq(message)
        end
      end

      describe '#message_verifier' do
        it 'return instance of ActiveSupport::MessageVerifier' do
          expect(::Logical::Naf::UserSession.message_verifier).to be_a(ActiveSupport::MessageVerifier)
        end
      end
    end

  end
end
