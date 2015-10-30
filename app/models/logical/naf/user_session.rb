module Logical
  module Naf
    class UserSession

      attr_reader :message

      def initialize(signed_message)
        @message = self.class.unsign_message(signed_message)
      end

      def valid?
        message.present? && message[:value].present? &&
          (Time.zone.now - message[:value]) < ::Naf.configuration.
            simple_cluster_authenticator_cookie_expiration_time
      end

      def token_cookie
        self.class.sign_message(self.class.build_token_cookie)
      end

      def self.build_token_cookie
        {
          value: Time.zone.now
        }
      end

      # Sign the provided string using a MessageVerifier.
      def self.sign_message(message)
        self.message_verifier.generate(message) unless message.nil?
      end

      # Unsign the provided string using a MessageVerifier.
      def self.unsign_message(message)
        if message.nil?
          return nil
        end

        begin
          self.message_verifier.verify(message)
        rescue ActiveSupport::MessageVerifier::InvalidSignature
          nil
        end
      end

      # Returns an ActiveSuport MessageVerifier for signing/unsigning strings seeded with the
      # applications secret token.
      def self.message_verifier
        @@message_verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.class.config.secret_token)
      end

    end
  end
end
