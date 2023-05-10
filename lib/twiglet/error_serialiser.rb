# frozen_string_literal: true

module Twiglet
  class ErrorSerialiser
    def serialise_error(error)
      error_fields = {
        error: {
          type: error.class.to_s,
          message: error.message
        }
      }
      add_stack_trace(error_fields, error)
    end

    private

    def add_stack_trace(hash_to_add_to, error)
      hash_to_add_to[:error][:stack_trace] = error.backtrace if error.backtrace
      hash_to_add_to
    end
  end
end
