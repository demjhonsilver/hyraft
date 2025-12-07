require_relative "../../test_helper"

class HomeAcceptanceTest < Minitest::Test
  include Rack::Test::Methods

  def app
    ->(env) { 
      [200, {'Content-Type' => 'text/html'}, ['Home page']] 
    }
  end

  def test_visit_homepage
    get '/'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Home page'
  end
end
