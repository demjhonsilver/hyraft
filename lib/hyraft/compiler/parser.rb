# lib/hyraft/compiler/parser.rb
module Hyraft
  module Compiler
    class HyraftParser
      def initialize(template)
        @template = template
      end

      def parse
        {
          metadata: extract('metadata','html'),
          metas:    extract('metas','html'),  
          displayer: extract('displayer','html'),
          transmuter: extract('transmuter','rb'),
          manifestor: extract('manifestor','js'),
          styles: @template.scan(/<style\s+src="([^"]+)"\s*\/?>/).flatten
        }
      end

      private

      def extract(tag, lang)
        @template[/<#{tag}\s+#{lang}>(.*?)<\/#{tag}>/m, 1]&.strip
      end
    end
  end
end