# lib/hyraft/compiler/compiler.rb
require_relative 'renderer'

module Hyraft
  module Compiler
    class HyraftCompiler
      def initialize(layout_file)
        @layout_file = layout_file
          @renderer = HyraftRenderer.new
      end

      # compile(view_file, data = {}) -> string
      def compile(view_file, data = {})
        layout_content = File.read(@layout_file)
        parsed = parse_hyraft(view_file)
        @renderer.render(layout_content, parsed, data)
      end

      private

      def parse_hyraft(file)
        content = File.read(file)
        {
          displayer:  content[/\<displayer html\>(.*?)\<\/displayer\>/m, 1],
          transmuter: content[/\<transmuter rb\>(.*?)\<\/transmuter\>/m, 1],
          styles:     content.scan(/<style\s+src="([^"]+)"\s*\/?>/).flatten, 
          manifestor: content[/\<manifestor js\>(.*?)\<\/manifestor\>/m, 1],
          metadata:   content[/\<metadata html\>(.*?)\<\/metadata\>/m, 1],
          metas:      content[/\<metas html\>(.*?)\<\/metas\>/m, 1]
        }
      end
    end
  end
end