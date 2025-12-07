# lib/hyraft/router/web_router.rb
module Hyraft
  module Router
    class WebRouter
      Route = Struct.new(:path, :method, :handler_class, :action, :template)

      def self.draw(&block)
        router = new
        router.instance_eval(&block)
        router
      end

      def initialize
        @routes = []
      end

      def GET(path, to:, template: nil)
        add_route('GET', path, to, template)
      end

      def POST(path, to:, template: nil)
        add_route('POST', path, to, template)
      end

      def PUT(path, to:, template: nil)
        add_route('PUT', path, to, template)
      end

      def DELETE(path, to:, template: nil)
        add_route('DELETE', path, to, template)
      end

      def add_route(method, path, to, template = nil)
        handler_class, action = to
        @routes << Route.new(path, method, handler_class, action, template)
      end

      def resolve(method, path)
        # Normalize path - remove trailing slashes except for root
        normalized_path = path.gsub(%r{/+$}, '')
        normalized_path = '/' if normalized_path.empty?
        
        # puts "DEBUG: Resolving #{method} #{path} -> normalized: #{normalized_path}"
        
        # First, try to find exact matches (non-parameter routes)
        exact_match = @routes.find do |r| 
          r.method == method && !r.path.include?(':') && !r.path.include?('*') && r.path == normalized_path
        end
        
        if exact_match
         # puts "DEBUG: Exact match found: #{exact_match.path}"
          return [exact_match, []]
        end
        
        # Then try parameter routes (routes with :)
        param_match = @routes.find do |r|
          r.method == method && r.path.include?(':') && !r.path.include?('*') && match_path(r.path, normalized_path)
        end
        
        if param_match
         # puts "DEBUG: Parameter match found: #{param_match.path}"
          params = extract_params(param_match.path, normalized_path)
          return [param_match, params]
        end
        
        # Finally try wildcard routes
        wildcard_match = @routes.find do |r|
          r.method == method && r.path.include?('*') && match_path(r.path, normalized_path)
        end
        
        if wildcard_match
         # puts "DEBUG: Wildcard match found: #{wildcard_match.path}"
          params = extract_params(wildcard_match.path, normalized_path)
          return [wildcard_match, params]
        end
        
        # puts "DEBUG: No route found for #{method} #{normalized_path}"
        nil
      end

      private

      def match_path(route_path, request_path)
        route_segments = route_path.split('/')
        request_segments = request_path.split('/')
        
        # Handle wildcard routes
        if route_path.include?('*')
          # For wildcard routes, check if the beginning matches
          wildcard_index = route_segments.index('*')
          return false unless wildcard_index
          
          # Check if all segments before the wildcard match
          (0...wildcard_index).each do |i|
            return false unless route_segments[i] == request_segments[i]
          end
          
          return true # Wildcard matches everything after
        end
        
        # For parameter routes, check segment count
        return false unless route_segments.length == request_segments.length

        # Check each segment
        route_segments.zip(request_segments).all? do |r, req|
          r.start_with?(':') || r == req
        end
      end

      def extract_params(route_path, request_path)
        route_segments = route_path.split('/')
        request_segments = request_path.split('/')
        
        params = []
        
        # Handle wildcard routes
        if route_path.include?('*')
          wildcard_index = route_segments.index('*')
          if wildcard_index
            # Capture everything after the wildcard as a single parameter
            captured_path = request_segments[wildcard_index..-1]&.join('/') || ''
            params << captured_path
          end
          return params
        end
        
        # Normal parameter extraction
        route_segments.zip(request_segments).each do |r, req|
          params << req if r.start_with?(':')
        end
        
        params
      end
    end
  end
end