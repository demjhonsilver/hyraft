# test/test_helper.rb
ENV['APP_ENV'] = 'test'

# Load Hyraft framework first
require 'hyraft'

require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/focus'
require 'mocha/minitest'
require 'rack/test'

Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new(color: true)
)

# Database testing configuration
ENV['TEST_NO_DB'] ||= '0'

def database_available?
  ENV['TEST_NO_DB'] == '0'
end

def skip_if_no_database
  skip "Database tests disabled (TEST_NO_DB=1)" unless database_available?
end

# Safe require helper that doesn't fail if files don't exist
def safe_require_root(path)
  full_path = File.expand_path("../#{path}.rb", __dir__)
  if File.exist?(full_path)
    require_relative "../#{path}"
    true
  else
    puts "Note: #{path} not found (this is normal in framework tests)"
    false
  end
end

# Try to load core components
components_loaded = safe_require_root('engine/source/article')
safe_require_root('engine/port/articles_gateway_port')
safe_require_root('engine/circuit/articles_circuit')

# Define mock classes ONLY if the real ones aren't loaded
unless defined?(Article)
  puts "Creating mock classes for framework testing..."
  
  # Mock Article class inheriting from Engine::Source
  class Article < Engine::Source
    attr_accessor :title, :content, :created_at, :updated_at, :status
    
    def initialize(id: nil, title: '', content: '', created_at: nil, updated_at: nil, status: :draft)
      super(id: id)
      @title = title
      @content = content
      @created_at = created_at || Time.now
      @updated_at = updated_at
      @status = status
    end
    
    def to_hash
      super.merge({
        title: @title,
        content: @content,
        created_at: @created_at,
        updated_at: @updated_at,
        status: @status
      })
    end
    
    def publish
      @status = :published
      @updated_at = Time.now
      self
    end
  end
end

unless defined?(ArticlesGatewayPort)
  # Mock ArticlesGatewayPort class inheriting from Engine::Port
  # This should be ABSTRACT to match test expectations - raises NotImplementedError
  class ArticlesGatewayPort < Engine::Port
    def save(entity)
      raise NotImplementedError, "Subclass must implement save"
    end
    
    def all
      raise NotImplementedError, "Subclass must implement all" 
    end
    
    def find(id)
      raise NotImplementedError, "Subclass must implement find"
    end
    
    def delete(id)
      raise NotImplementedError, "Subclass must implement delete"
    end
  end
end

# Create a concrete implementation for other tests that need working gateways
unless defined?(MockArticlesGateway)
  class MockArticlesGateway < ArticlesGatewayPort
    def save(entity)
      return nil if entity.nil?
      entity.id ||= rand(1000).to_s
      entity
    end
    
    def all
      [Article.new]
    end
    
    def find(id)
      Article.new(id: id, title: "Mock Article")
    end
    
    def delete(id)
      true
    end
  end
end




unless defined?(ArticlesCircuit)
  # Mock ArticlesCircuit class inheriting from Engine::Circuit
  class ArticlesCircuit < Engine::Circuit
    def initialize(gateway = MockArticlesGateway.new)  # ← Change this line
      @gateway = gateway
    end
    
    def create(title:, content:)
      return nil if title.to_s.strip.empty? || content.to_s.strip.empty?
      
      articles = @gateway.all
      max_id = articles.map { |a| a.id.to_i }.max || 0
      id = (max_id + 1).to_s
      article = Article.new(id: id, title: title, content: content)
      @gateway.save(article)
      article
    end
    
    def list
      @gateway.all
    end
    
    def find(id)
      @gateway.find(id)
    end
    
    def update(id:, title:, content:)
      return nil if title.to_s.strip.empty? || content.to_s.strip.empty?
      
      article = @gateway.find(id)
      return nil unless article
      
      updated_article = Article.new(id: id, title: title, content: content)
      @gateway.save(updated_article)
    end
    
    def delete(id)
      article = @gateway.find(id)
      return nil unless article
      
      @gateway.delete(id)
    end
    
    def execute(input = {})
      operation = input[:operation]
      params = input[:params] || {}
      
      case operation
      when :create then create(**params)
      when :list then list
      when :find then find(params[:id])
      when :update then update(**params)
      when :delete then delete(params[:id])
      else
        raise "Unknown operation: #{operation}"
      end
    end
  end
end



# Mock adapter classes for when real adapters don't exist
unless defined?(ArticlesWebAdapter)
  class ArticlesWebAdapter
    def initialize
      # Use mock circuit for testing
      @articles = ArticlesCircuit.new(ArticlesGatewayPort.new)
    end

    # GET /articles
    def index(request)
      articles = @articles.list || []
      
      {
        status: 200,
        locals: { 
          articles: articles
        },
        display: 'pages/articles/index.hyr'
      }
    end

    # GET /articles/:id
    def show(request)
      id = request.params['route_params'].first
      article = @articles.find(id)

      if article
        {
          status: 200,
          locals: { 
            article: article
          },
          display: 'pages/articles/show.hyr'
        }
      else
        not_found_response(request)
      end
    end

    # GET /articles/new - Show create form
    def new(request)
      {
        status: 200,
        locals: {},
        display: 'pages/articles/new.hyr'
      }
    end

    # POST /articles - Create article
    def create(request)
      data = request.params['data'] || {}
      
      if data['title'] && data['content']
        article = @articles.create(
          title: data['title'],
          content: data['content']
        )
        
        {
          status: 303,
          headers: { 'Location' => "/articles" },
          locals: {}
        }
      else
        {
          status: 422,
          locals: { 
            error: "Title and content are required"
          },
          display: 'pages/articles/new.hyr'
        }
      end
    end

    # GET /articles/:id/edit - Show edit form
    def edit(request)
      id = request.params['route_params'].first
      article = @articles.find(id)
      
      if article
        {
          status: 200,
          locals: { 
            article: article
          },
          display: 'pages/articles/edit.hyr'
        }
      else
        not_found_response(request)
      end
    end

    # PUT /articles/:id - Update article
    def update(request)
      id = request.params['route_params'].first
      data = request.params['data'] || {}
      
      updated_article = @articles.update(
        id: id,
        title: data['title'],
        content: data['content']
      )
      
      if updated_article
        {
          status: 303,
          headers: { 'Location' => "/articles" },
          locals: {}
        }
      else
        {
          status: 422,
          locals: { 
            article: @articles.find(id),
            error: "Failed to update article" 
          },
          display: 'pages/articles/edit.hyr'
        }
      end
    end

    # DELETE /articles/:id - Delete article
    def delete(request)
      id = request.params['route_params'].first
      @articles.delete(id)
      
      {
        status: 303,
        headers: { 'Location' => "/articles" },
        locals: {}
      }
    end

    private

    def not_found_response(request)
      {
        status: 404,
        locals: { 
          error: "Article not found",
          back_url: '/articles',  
          back_text: 'Back to articles'  
        },
        display: 'pages/articles/404.hyr'
      }
    end
  end
end

unless defined?(HomeWebAdapter)
  class HomeWebAdapter
    def call(request)
      {
        status: 200,
        locals: {},
        display: 'pages/home/index.hyr'
      }
    end
  end
end

unless defined?(ArticlesApiAdapter)
  class ArticlesApiAdapter
    def index(request)
      articles = [Article.new].map(&:to_hash)
      {
        status: 200,
        locals: { articles: articles },
        display: nil # JSON response
      }
    end
    
    def show(request)
      id = request.params['route_params'].first
      {
        status: 200,
        locals: { article: Article.new(id: id).to_hash },
        display: nil # JSON response
      }
    end
  end
end

# Conditionally load database components
if database_available?
  puts "Loading database components..."
  if safe_require_root('infra/database/sequel_connection')
    safe_require_root('adapter-exhaust/data-gateway/sequel_articles_gateway')
  end
else
  puts "Skipping database components (TEST_NO_DB=1)"
  # Load mock components instead
  if File.exist?(File.join(__dir__, 'support', 'mock_articles_gateway.rb'))
    require_relative 'support/mock_articles_gateway'
  end
end

# Load adapters if they exist
safe_require_root('adapter-intake/web-app/request/articles_web_adapter')
safe_require_root('adapter-intake/web-app/request/home_web_adapter')

# Load API adapter if it exists
begin
  safe_require_root('adapter-intake/api-app/request/articles_api_adapter')
rescue LoadError => e
  puts "Note: ArticlesApiAdapter not found: #{e.message}"
end

# Load test support files
if Dir.exist?(File.join(__dir__, 'support'))
  Dir[File.join(__dir__, 'support', '*.rb')].each { |f| require f }
end

# Apply test patches when not using database
if File.exist?(File.join(__dir__, 'support', 'test_patches.rb'))
  require_relative 'support/test_patches' unless database_available?
end

class Minitest::Test
  def setup
    setup_test_database if database_available?
  end

  def teardown
    clear_test_data if database_available?
  end

  def setup_test_database
    return unless database_available?
    
    # Only setup database if SequelConnection is available
    if defined?(SequelConnection) && SequelConnection.respond_to?(:db)
      db = SequelConnection.db
      
      # Run migrations if they haven't been run
      migrations_dir = File.join(__dir__, '..', 'infra', 'database', 'migrations')
      if Dir.exist?(migrations_dir) && db.tables.include?(:schema_migrations)
        puts "Running test database migrations..."
        Sequel::Migrator.run(db, migrations_dir)
      end
    end
  end

  def clear_test_data
    return unless database_available?
    
    if defined?(SequelConnection) && SequelConnection.respond_to?(:db)
      db = SequelConnection.db
      db[:articles].delete if db.tables.include?(:articles)
    end
  end

  def create_test_article(attributes = {})
    Article.new(
      id: attributes[:id] || rand(1000).to_s,
      title: attributes[:title] || "Test Article",
      content: attributes[:content] || "Test content",
      created_at: attributes[:created_at] || Time.now,
      updated_at: attributes[:updated_at] || Time.now,
      status: attributes[:status] || :draft
    )
  end


  # In the Minitest::Test class, update the articles_gateway method:
  def articles_gateway
    if database_available? && defined?(SequelArticlesGateway)
      SequelArticlesGateway.new
    else
      # Always use the concrete mock implementation
      MockArticlesGateway.new
    end
  end

  # Helper to create circuit with appropriate gateway
  def articles_circuit
    ArticlesCircuit.new(articles_gateway)
  end
end



  # Run all tests
=begin

rake test

# Or run specific test types
rake test:unit
rake test:integration

# Run single test file
ruby -I test test/unit/engine/source/article_test.rb


# Check what require statements you currently have
grep -r "require_relative.*test_helper" test/


ruby test/db.rb

to Run test and save to database:

APP_ENV=test hyr s thin

to run in PROD:

APP_ENV=production hyr s thin

APP_ENV=production hyr s thin --api



# Run only unit tests (no database needed)
TEST_NO_DB=1 rake test test/unit/

# Run only acceptance tests  
TEST_NO_DB=1 rake test test/acceptance/

# Run only integration tests that don't need database
TEST_NO_DB=1 rake test test/integration/adapter-intake/


# Run WITHOUT database (--------------------------)
TEST_NO_DB=1 rake test

# Run WITH database (if available)
rake test


Environment	Server	                                Migrations

Development	   hyr s thin	                         hyraft-rule-migrate migrate
Test	         APP_ENV=test hyr s thin	           APP_ENV=test hyraft-rule-migrate migrate
Production	   APP_ENV=production hyr s thin	     APP_ENV=production hyraft-rule-migrate migrate

=end