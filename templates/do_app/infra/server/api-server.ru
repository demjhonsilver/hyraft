# server/api-server.ru
require_relative './../../boot'
require 'hyraft/server'
# Import the CORS middleware
require_relative '../../framework/middleware/cors_middleware'

use CorsMiddleware
use ApiLogger


app = ServerApiAdapter.new

run app