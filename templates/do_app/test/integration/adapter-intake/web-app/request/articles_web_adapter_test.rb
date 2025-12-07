# test/integration/adapter-intake/web-app/request/articles_web_adapter_test.rb
require_relative "../../../../test_helper"

class ArticlesWebAdapterTest < Minitest::Test
  def setup
    @adapter = ArticlesWebAdapter.new
  end

  def test_index_action
    request = mock('request')
    request.stubs(:params).returns({})
    
    response = @adapter.index(request)
    
    assert_equal 200, response[:status]
    assert_equal 'pages/articles/index.hyr', response[:display]
    assert response[:locals][:articles]
    assert_kind_of Array, response[:locals][:articles]
  end
end