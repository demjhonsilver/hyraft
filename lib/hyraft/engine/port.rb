# frozen_string_literal: true

module Hyraft
  class Port
    def implementor=(adapter)
      @implementor = adapter
    end
    
    def method_missing(method, *args, &block)
      if @implementor&.respond_to?(method)
        @implementor.send(method, *args, &block)
      else
        super
      end
    end
  end
end