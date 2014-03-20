require 'spec_helper'

module Logical
  module Naf

    describe UserSession do
      let!(:user_session) { ::Logical::Naf::UserSession.new(nil) }

      describe '#valid?' do
        it 'return false when message is not present' do
          user_session.valid?.should be_false
        end

        it 'return false when value is not present' do
          user_session.instance_variable_set(:@message, {})
          user_session.valid?.should be_false
        end

        it 'return false when session is expired' do
          user_session.instance_variable_set(:@message, { value: Time.zone.now - 1.month })
          user_session.valid?.should be_false
        end

        it 'return true for invalid signed message' do
          user_session.instance_variable_set(:@message, { value: Time.zone.now - 1.hour })
          user_session.valid?.should be_true
        end
      end

      describe '#token_cookie' do
        let!(:signed_message) { user_session.token_cookie }

        it 'not be nil' do
          signed_message.should_not be_nil
        end

        it 'encoded correctly' do
          signed_message.should =~ /^.{123}={1}-{2}[a-zA-Z0-9]{40}$/
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
          ::Logical::Naf::UserSession.build_token_cookie.should == { value: Time.zone.now }
        end
      end

      describe '#sign_message' do
        it 'return nil when message is nil' do
          ::Logical::Naf::UserSession.sign_message(nil).should be_nil
        end

        it 'sign the message when message is present' do
          ::Logical::Naf::UserSession.sign_message(::Logical::Naf::UserSession.build_token_cookie).
            should =~ /^.{123}={1}-{2}[a-zA-Z0-9]{40}$/
        end
      end

      describe '#signed_message?' do
        it 'return false when message is nil' do
          ::Logical::Naf::UserSession.signed_message?(nil).should be_false
        end

        it 'return false when message is not encoded' do
          ::Logical::Naf::UserSession.signed_message?({ value: Time.zone.now }).should be_false
        end

        it 'return 0 when message is signed' do
          ::Logical::Naf::UserSession.signed_message?(user_session.token_cookie).should == 0
        end
      end

      describe '#unsign_message' do
        it 'return nil when message is not signed' do
          ::Logical::Naf::UserSession.unsign_message(nil).should be_nil
        end

        it 'return nil when InvalidSignature exception is raised' do
          ::Logical::Naf::UserSession.should_receive(:signed_message?).and_return(0)
          ::Logical::Naf::UserSession.unsign_message(nil).should be_nil
        end

        it 'return message when signed message is valid' do
          message_verifier = ActiveSupport::MessageVerifier.
            new(Rails.application.class.config.secret_token)
          message = { value: Time.zone.now }

          ::Logical::Naf::UserSession.
            unsign_message(message_verifier.generate(message)).should == message
        end
      end

      describe '#message_verifier' do
        it 'return instance of ActiveSupport::MessageVerifier' do
          ::Logical::Naf::UserSession.message_verifier.should be_a(ActiveSupport::MessageVerifier)
        end
      end
    end

  end
end
