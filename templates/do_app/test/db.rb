# test/db.rb

require 'yaml'
require 'sequel'

# Load environment config
config = YAML.load_file('env.yml')
test_config = config['test'] # test /development / production

puts "Testing database connection with config:"
puts "  Database: #{test_config['DB_DATABASE']}"
puts "  Adapter: #{test_config['DB_CONNECTION']}"
puts "  Host: #{test_config['DB_HOST']}"

begin
  # Map adapter names for Sequel
  adapter = case test_config['DB_CONNECTION'].to_s.downcase
            when 'mysql', 'mysql2' then 'mysql2'
            when 'postgres', 'postgresql', 'pgsql' then 'postgres'
            when 'sqlite', 'sqlite3' then 'sqlite'
            else
              test_config['DB_CONNECTION']
            end

  # Build connection options based on adapter type
  connection_options = {
    adapter: adapter,
    database: test_config['DB_DATABASE']
  }

  # Add common options for client-server databases
  case adapter
  when 'mysql2', 'postgres'
    connection_options[:host] = test_config['DB_HOST'] if test_config['DB_HOST']
    connection_options[:port] = test_config['DB_PORT'] if test_config['DB_PORT']
    connection_options[:user] = test_config['DB_USERNAME'] if test_config['DB_USERNAME']
    connection_options[:password] = test_config['DB_PASSWORD'] if test_config['DB_PASSWORD']
    connection_options[:encoding] = test_config['DB_CHARSET'] if test_config['DB_CHARSET']
    
    # MySQL-specific options
    if adapter == 'mysql2'
      # Only use socket if specified and file exists
      if test_config['DB_SOCKET'] && File.exist?(test_config['DB_SOCKET'])
        connection_options[:socket] = test_config['DB_SOCKET']
        puts "  Using socket: #{test_config['DB_SOCKET']}"
      else
        puts "  Using TCP connection"
      end
    end
    
  when 'sqlite'
    # SQLite doesn't need host/port/user/password
    puts "  Using SQLite database file"
  else
    puts "  Unknown adapter: #{adapter}, using basic connection"
  end

  puts "  Connection options: #{connection_options.reject { |k,v| k == :password }}"

  # Connect to the database
  db = Sequel.connect(connection_options)

  # Test connection
  db.test_connection
  puts "✅ Database connection successful!"

  # Show tables
  tables = db.tables
  if tables.any?
    puts "📊 Tables in database: #{tables.join(', ')}"
  else
    puts "📊 No tables in database"
  end

  # Show database version
  begin
    version = case adapter
              when 'mysql2' then db['SELECT VERSION() as version'].first[:version]
              when 'postgres' then db['SELECT version()'].first[:version].split(',')[0]
              when 'sqlite' then db['SELECT sqlite_version()'].first.values.first
              else "Unknown"
              end
    puts "🔧 Database version: #{version}"
  rescue => e
    puts "🔧 Could not determine database version: #{e.message}"
  end

  db.disconnect

rescue LoadError => e
  puts "❌ Missing gem: #{e.message}"
  puts "💡 Tip: Make sure the required database gem is installed:"
  case adapter
  when 'mysql2' then puts "       gem install mysql2"
  when 'postgres' then puts "       gem install pg"
  when 'sqlite' then puts "       gem install sqlite3"
  end
rescue => e
  puts "❌ Database connection failed: #{e.message}"
  puts "💡 Debug info:"
  puts "   - Adapter: #{adapter}"
  puts "   - Connection options used: #{connection_options.reject { |k,v| k == :password }.inspect}"
  if test_config['DB_SOCKET']
    puts "   - Socket file exists: #{File.exist?(test_config['DB_SOCKET'])}"
  end
end