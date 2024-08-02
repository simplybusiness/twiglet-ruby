module Twiglet
  class Message < Hash
    def initialize(msg)
      super
      case msg
      when String
        self[:message] = msg
      when Hash
        replace(msg.transform_keys!(&:to_sym))
      else
        super
      end
    end
  end
end
