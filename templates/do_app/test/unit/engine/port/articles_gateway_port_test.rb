require_relative "./../../../test_helper"

class ArticlesGatewayPortTest < Minitest::Test
  def test_interface_methods
    port = ArticlesGatewayPort.new
    
    assert_raises(NotImplementedError) { port.save(nil) }
    assert_raises(NotImplementedError) { port.all }
    assert_raises(NotImplementedError) { port.find("1") }
    assert_raises(NotImplementedError) { port.delete("1") }
  end
end
