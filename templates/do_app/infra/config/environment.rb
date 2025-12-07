# infra/config/environment.rb
require 'yaml'

module Environment
  # Color methods
  def self.colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end

  def self.green(text)
    colorize(text, 32)
  end

  def self.red(text)
    colorize(text, 31)
  end

  def self.yellow(text)
    colorize(text, 33)
  end

  def self.blue(text)
    colorize(text, 34)
  end

  def self.magenta(text)
    colorize(text, 35)
  end

  def self.cyan(text)
    colorize(text, 36)
  end

  def self.bold(text)
    colorize(text, 1)
  end

  # Environment-specific colors
  def self.environment_color
    case current
    when 'development' then cyan(current)
    when 'test' then green(current)  # Lime/Green for test
    when 'production' then red(current)
    else yellow(current)
    end
  end

  def self.load_config
    env_file = File.expand_path('../../../env.yml', __dir__)
    if File.exist?(env_file)
      YAML.load_file(env_file)
    else
      {}
    end
  end

  def self.current
    ENV['APP_ENV'] || 'development'
  end

  def self.config
    @config ||= load_config
    @config[self.current] || {}
  end

  def self.database_url
    db_config = config
    if db_config['DB_SOCKET']
      "mysql2://#{db_config['DB_USERNAME']}:#{db_config['DB_PASSWORD']}@#{db_config['DB_HOST']}#{db_config['DB_SOCKET']}/#{db_config['DB_DATABASE']}"
    else
      "mysql2://#{db_config['DB_USERNAME']}:#{db_config['DB_PASSWORD']}@#{db_config['DB_HOST']}:#{db_config['DB_PORT']}/#{db_config['DB_DATABASE']}"
    end
  end

  def self.development?
    current == 'development'
  end

  def self.production?
    current == 'production'
  end

  def self.test?
    current == 'test'
  end
end