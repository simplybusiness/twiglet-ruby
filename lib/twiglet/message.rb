module Twiglet
  class Message < Hash
    def initialize(msg)
      case msg
      when String
        self[:message] = msg
      when Hash
        replace(msg.transform_keys!(&:to_sym))
      else
        super(msg)
      end

      validate!
    end

    private

    def validate!
      raise 'Message must be initialized with a String or a non-empty Hash' if empty?

      raise 'Log object must have a \'message\' property' unless self[:message]

      raise 'The \'message\' property of the log object must not be empty' if self[:message].strip.empty?
    end
  end
end
