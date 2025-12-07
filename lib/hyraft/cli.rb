# frozen_string_literal: true
# hyraft/lib/hyraft/cli.rb

require 'fileutils'
require 'set'

module Hyraft
  class CLI
    def self.start(argv)
      new(argv).execute
    end

    def initialize(argv)
      @argv = argv
      @command = argv[0]
      @app_name = argv[1]
    end

    def execute
      case @command
      when "do" 
        do_application
      when "version", "-v", "--version"
        puts "Hyraft version #{VERSION}"
      when nil, "help", "-h", "--help"
        show_help
      else
        puts "Unknown command: #{@command}"
        show_help
      end
    end

    private

    def show_help
      puts "Hyraft - Hexagonal Architecture Framework"
      puts "Commands:"
      puts "  set APP_NAME    Create a new Hyraft application" 
      puts "  version         Show version information"
      puts "  help            Show this help message"
    end

    def do_application
      return puts "Error: Need app name" unless @app_name
      
      template_dir = find_template_dir
      unless template_dir && Dir.exist?(template_dir)
        puts "Error: Could not find template directory"
        exit 1
      end

      target_dir = File.expand_path(@app_name)
      
      if Dir.exist?(target_dir)
        puts "Error: Directory '#{@app_name}' already exists"
        exit 1
      end
      
      puts "Creating Hyraft application: #{@app_name}"
      copy_template_structure(template_dir, target_dir)
      ensure_hexagonal_structure(target_dir)
      create_env_file(target_dir)
      puts "✅ Hyraft app '#{@app_name}' created successfully!"
      puts "   cd #{@app_name}"
      puts "   bundle install && npm install"
      puts "   hyraft-server thin"
    end

    def find_template_dir
      locations = [
        -> { 
          gem_spec = Gem::Specification.find_by_name('hyraft')
          File.join(gem_spec.gem_dir, 'templates', 'do_app')
        },
        -> { File.expand_path('../../templates/do_app', __dir__) },
        -> { File.expand_path('templates/do_app', Dir.pwd) }
      ]
      
      locations.each do |location_proc|
        begin
          dir = location_proc.call
          return dir if Dir.exist?(dir)
        rescue Gem::LoadError, StandardError
          next
        end
      end
      
      nil
    end

    def copy_template_structure(source, destination)
      FileUtils.mkdir_p(destination)
      copy_entire_structure(source, destination)
    end

    def copy_entire_structure(source, destination)
      require 'find'
      copied_paths = Set.new
      
      Find.find(source) do |path|
        next if path == source
        relative_path = path.sub("#{source}/", '')
        target_path = File.join(destination, relative_path)
        next if copied_paths.include?(relative_path)
        copied_paths.add(relative_path)
        
        if File.directory?(path)
          FileUtils.mkdir_p(target_path)
          puts "   create #{target_path}/" unless Dir.empty?(path)
        else
          FileUtils.mkdir_p(File.dirname(target_path))
          FileUtils.cp(path, target_path)
          puts "   create #{target_path}"
        end
      end
    end

    def ensure_hexagonal_structure(app_dir)
      hex_dirs = [
        'engine/circuit',
        'engine/port',
        'engine/source',
        'adapter-intake/api-app/request',
        'adapter-intake/web-app/request',
        'adapter-exhaust/data-gateway/',
        'infra/database/migrations',
        'public/uploads',
      ]
      
      puts "Ensuring hexagonal architecture structure..."
      
      hex_dirs.each do |dir|
        full_path = File.join(app_dir, dir)
        unless Dir.exist?(full_path)
          FileUtils.mkdir_p(full_path)
          puts "   create #{full_path}/" if Dir.empty?(full_path)
        end
      end
    end

    def create_env_file(app_dir)
      env_path = File.join(app_dir, 'env.yml')
      
      env_content = <<~YAML
# env.yml

# Application Settings

APP_NAME: myapp
SERVER_PORT: 1091
SERVER_PORT_API: 1092

development:
  DB_CONNECTION: mysql
  DB_HOST: localhost      
  DB_PORT: 3306           
  DB_DATABASE: myapp_development
  DB_USERNAME: root
  DB_PASSWORD: 
  DB_CHARSET: utf8mb4


test:
  DB_CONNECTION: mysql
  DB_HOST: localhost       
  DB_PORT: 3306
  DB_DATABASE: myapp_test
  DB_USERNAME: root
  DB_PASSWORD: 
  DB_CHARSET: utf8mb4
 

production:
  DB_CONNECTION: mysql
  DB_HOST: localhost       
  DB_PORT: 3306
  DB_DATABASE: myapp_production
  DB_USERNAME: 
  DB_PASSWORD: 
  DB_CHARSET: utf8mb4
      YAML
      
      File.write(env_path, env_content)
      puts "   create #{env_path}"
    end
  end
end
