# framework/middleware/cors_middleware.rb
class CorsMiddleware
  def initialize(app)
    @app = app
    # puts "CORS Middleware initialized!"
  end

  def call(env)
   # puts "CORS Middleware processing: #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
    
    # Handle preflight OPTIONS request
    if env['REQUEST_METHOD'] == 'OPTIONS'
    #  puts "Handling OPTIONS preflight request"
      return [200, cors_headers, []]
    end

    status, headers, body = @app.call(env)
    
    # Add CORS headers to all responses
   # puts "Adding CORS headers to response"
    headers.merge!(cors_headers)
    
    [status, headers, body]
  end

  private

  def cors_headers
    {
      'Access-Control-Allow-Origin' => 'http://localhost:1091',
      'Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers' => 'Content-Type, Authorization, X-Requested-With',
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Max-Age' => '86400'
    }
  end
end