module Twiglet
  class Message
    attr_reader :content

    def self.format(msg)
      new(msg).content
    end

    def initialize(msg)
      case msg
      when String
        @content = { message: msg }
      when Hash
        @content = msg.transform_keys!(&:to_sym)
      else
        raise('Message must be String or Hash')
      end

      validate!
    end

    private

    def validate!
      message = content.fetch(:message) { raise('Log object must have a \'message\' property') }
      raise('The \'message\' property of the log object must not be empty') if message.strip.empty?
    end
  end
end
