# lib/hyraft/router/api_router.rb
module Hyraft
  module Router
    class ApiRouter
      Route = Struct.new(:http_method, :path, :handler_class, :action_name, :regex)

      def initialize
        @routes = []
      end

      def self.draw(&block)
        router = new
        router.instance_eval(&block)
        router
      end

      def GET(path, to:)
        add_route('GET', path, to)
      end

      def POST(path, to:)
        add_route('POST', path, to)
      end

      def PUT(path, to:)
        add_route('PUT', path, to)
      end

      def DELETE(path, to:)
        add_route('DELETE', path, to)
      end

      def resolve(http_method, path_info)
        path = path_info.split('?').first
        
        # Try exact matches first
        exact_match = @routes.find do |r| 
          r.http_method == http_method && r.path == path
        end
        return [exact_match, []] if exact_match
        
        # Then try regex matches
        @routes.each do |r|
          if r.http_method == http_method && (match = r.regex.match(path))
            return [r, match.captures]
          end
        end
        
        nil
      end

      def add_route(http_method, path, to)
        handler_class, action_name = to
        regex = compile(path)
        @routes << Route.new(http_method, path, handler_class, action_name, regex)
      end

      private

      def compile(path)
        Regexp.new("^" + path.gsub(/:([a-zA-Z_]\w*)/, '([^/]+)') + "$")
      end
    end
  end
end