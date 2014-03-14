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
          value: Time.zone.now,
          expires: 1.week.from_now,
          domain: self.host_domain
        }
      end

      def self.host_domain
        if Rails.env == 'development'
          "localhost:#{Rails::Server.new.options[:Port]}"
        else
          '*.' + Socket.gethostname.split('/')[0].split('.')[-2..-1].join('.')
        end
      end

      # Sign the provided string using a MessageVerifier.
      def self.sign_message(message)
        self.message_verifier.generate(message) if !message.nil?
      end

      # Returns true if the provided string is signed with MessageVerifier.  A signed
      # string is composed of two sections separate by two dashes: the string base64 encoded
      # and a SHA1 hash digest of the string.
      def self.signed_message?(message)
        !message.nil? && message =~ /^[a-zA-z0-9]+={0,2}--[a-zA-z0-9]{40}$/
      end

      # Unsign the provided string using a MessageVerifier.
      def self.unsign_message(message)
        return nil unless self.signed_message?(message)
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
