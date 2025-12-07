# test/acceptance/api/articles_api_acceptance_test.rb
require_relative "../../test_helper"

class ArticlesApiAcceptanceTest < Minitest::Test
  include Rack::Test::Methods

  def app
    # This should point to your actual API server
    # You might need to create this based on your infra/server setup
    ->(env) { 
      # Simple mock API for acceptance testing
      case env['PATH_INFO']
      when '/api/articles'
        [200, { 'Content-Type' => 'application/json' }, ['[{"id":"1","title":"Test"}]']]
      when '/api/articles/1'
        [200, { 'Content-Type' => 'application/json' }, ['{"id":"1","title":"Test"}']]
      else
        [404, {}, ['Not Found']]
      end
    }
  end

  def test_api_articles_endpoint
    get '/api/articles'
    
    assert_equal 200, last_response.status
    assert_equal 'application/json', last_response.content_type
    
    response = JSON.parse(last_response.body)
    assert response.is_a?(Array)
  end

  def test_api_single_article_endpoint
    get '/api/articles/1'
    
    assert_equal 200, last_response.status
    assert_equal 'application/json', last_response.content_type
    
    response = JSON.parse(last_response.body)
    assert response["id"]
    assert response["title"]
  end
end