# frozen_string_literal: true

module Hyraft
  class Circuit
    def initialize(ports = {})
      @ports = ports
    end

    # Magic: Automatically route custom methods to execute
    def method_missing(method, *args, &block)
      if respond_to_missing?(method)
        execute(operation: method, params: args.first || {})
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      # Check if it's a public method defined in the subclass OR
      # if the execute method can handle it
      self.class.public_method_defined?(method) || can_handle_operation?(method)
    end

    def execute(input = {})
      raise NotImplementedError, "Circuits must implement execute method"
    end

    private

    def can_handle_operation?(operation)
      # Subclasses should override this to return true for operations they handle
      false
    end
  end
end