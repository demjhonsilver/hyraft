# boot.rb
require 'bundler/setup'
require_relative 'infra/gems/load_all'

require 'hyraft'
require 'sequel'

require_relative 'framework/middleware/cors_middleware'

ROOT = File.expand_path(__dir__) unless defined?(ROOT)

def require_root(path)
  full_path = File.join(ROOT, path)
  require full_path
end

# Load environment configuration FIRST
require_relative 'infra/config/environment'

# Load middleware
Dir["#{ROOT}/framework/middleware/*.rb"].each { |file| require file }



  Dir["#{ROOT}/**/*.rb"].each do |file|
    # Skip files that should not be auto-loaded
    next if file.include?('framework/middleware/') || 
            file.include?('boot.rb') || 
            file.end_with?('.ru') ||
            file.end_with?('.hyr') ||
            file.include?('infra/database/migrations/') ||
            file.include?('test/')  # Skip test files
    require file
  end


# Initialize the application after all files are loaded
Hyraft::Environment.load if defined?(Hyraft::Environment)

# Use the Environment module
puts "Starting #{Environment.environment_color} environment"