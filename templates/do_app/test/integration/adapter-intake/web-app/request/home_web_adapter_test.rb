require_relative "../../../../test_helper"

class HomeWebAdapterTest < Minitest::Test
  def setup
    @adapter = HomeWebAdapter.new
  end

  def test_home_page
    request = mock('request')
    
    response = @adapter.home_page(request)
    
    assert_equal 200, response[:status]
    assert_equal 'home/home.hyr', response[:display]
    assert_equal "Welcome to Hyraft", response[:locals][:page_title]
  end
end
