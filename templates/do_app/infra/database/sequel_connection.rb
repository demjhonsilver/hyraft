# infra/database/sequel_connection.rb
require 'sequel'
require 'yaml'
require_relative '../config/environment'

class SequelConnection
  class << self
    # Public method
    def db
      @db ||= connect
    end

    private

    # Keep connect private
    def connect
      env = Environment.current

      config_path = File.expand_path('../../env.yml', __dir__)
      raise "env.yml not found at #{config_path}" unless File.exist?(config_path)

      full_config = YAML.load_file(config_path)
      db_config = full_config[env] || {}

      adapter_map = {
        'pgsql'      => 'postgres',
        'postgres'   => 'postgres',
        'postgresql' => 'postgres',
        'mysql'      => 'mysql2',
        'sqlite'     => 'sqlite'
      }

      adapter_name = adapter_map[db_config['DB_CONNECTION']]
      raise "Unsupported DB_CONNECTION: #{db_config['DB_CONNECTION']}" unless adapter_name

      required_keys = %w[DB_CONNECTION DB_HOST DB_DATABASE DB_USERNAME DB_PASSWORD DB_PORT]
      missing_keys = required_keys.select { |k| db_config[k].nil? || db_config[k].to_s.strip.empty? }
      raise "Missing DB configuration keys: #{missing_keys.join(', ')}" if missing_keys.any?

      # Build connection options
      connection_options = {
        adapter:  adapter_name,
        host:     db_config['DB_HOST'],
        database: db_config['DB_DATABASE'],
        user:     db_config['DB_USERNAME'],
        password: db_config['DB_PASSWORD'],
        port:     db_config['DB_PORT']
      }

      # Add socket for MySQL if specified for linux
      if db_config['DB_SOCKET'] && adapter_name == 'mysql2'
        connection_options[:socket] = db_config['DB_SOCKET']
        # add this to env.yml:  DB_SOCKET: /opt/lampp/var/mysql/mysql.sock 
      end

      Sequel.connect(connection_options)
    rescue => e
      puts "DB Connection failed: #{e.message}"
      raise e
    end
  end
end