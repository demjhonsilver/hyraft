# frozen_string_literal: true

module Hyraft
  class Source
    attr_accessor :id

    def initialize(attributes = {})
      @id = attributes[:id]
    end

    def to_hash
      { id: @id }
    end
    
    def persisted?
      !@id.nil?
    end
  end
end