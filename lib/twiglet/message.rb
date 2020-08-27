module Twiglet
  class Message < Hash
    def initialize(msg)
      case msg
      when String
        self[:message] = msg
      when Hash
        replace(msg.transform_keys!(&:to_sym))
      end

      validate!
    end

    private

    def validate!
      raise 'Message must be initialized with a String or a non-empty Hash' if empty?

      message = fetch(:message) { raise('Log object must have a \'message\' property') }
      raise('The \'message\' property of the log object must not be empty') if message.strip.empty?
    end
  end
end
