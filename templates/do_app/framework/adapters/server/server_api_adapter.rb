# framework/adapters/server/server_api_adapter.rb
require 'cgi'

class ServerApiAdapter
  def initialize(router = Api)
    @router = router
  end

  def call(rack_env)
    req = Rack::Request.new(rack_env)
    
    # Pass full path with query string to router
    full_path = req.path_info + (req.query_string.empty? ? '' : "?#{req.query_string}")
    route, route_params = @router.resolve(req.request_method, full_path)

    if route
      handler_class = route.handler_class
      action = route.action_name
      handler = handler_class.new

      # Create clean request object
      request_object = {
        query_string: req.query_string,
        query_params: CGI.parse(req.query_string).transform_values { |v| v.length == 1 ? v.first : v },
        body: req.body&.read,
        headers: {
          content_type: req.content_type,
          content_length: req.content_length
        }
      }

      # Read body for POST/PUT
      if req.post? || req.put?
        request_object[:body] = req.body.read
        req.body.rewind
      end

      # Call handler with clean request object
      if [:show, :update, :delete].include?(action)
        # Pass route param (id) as separate argument
        id = route_params.first if route_params.any?
        handler.public_send(action, request_object, id)
      else
        # No route params for index/create
        handler.public_send(action, request_object)
      end
    else
      [404, { 'Content-Type' => 'application/json' }, [{ error: 'Not Found' }.to_json]]
    end
  end
end