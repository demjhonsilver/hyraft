require_relative "../../test_helper"

class ArticlesWebAcceptanceTest < Minitest::Test
  include Rack::Test::Methods

  def app
    ->(env) { 
      [200, {'Content-Type' => 'text/html'}, ['Test response']] 
    }
  end

  def test_visit_articles_index
    get '/articles'
    assert_equal 200, last_response.status
  end

  def test_visit_article_show
    get '/articles/1'
    assert_equal 200, last_response.status
  end

  def test_visit_new_article_page
    get '/articles/new'
    assert_equal 200, last_response.status
  end

  def test_visit_edit_article_page
    get '/articles/1/edit'
    assert_equal 200, last_response.status
  end
end
