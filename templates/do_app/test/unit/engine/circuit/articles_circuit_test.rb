# test/unit/engine/circuit/articles_circuit_test.rb
require_relative "../../../test_helper"

class ArticlesCircuitTest < Minitest::Test
  def setup
    @mock_gateway = mock('gateway')
    @circuit = ArticlesCircuit.new(@mock_gateway)
  end

  def test_create_article
    article_data = { title: "Test", content: "Content" }
    mock_article = Article.new(id: "1", title: "Test", content: "Content")
    
    @mock_gateway.expects(:all).returns([])
    @mock_gateway.expects(:save).returns(mock_article)
    
    result = @circuit.create(**article_data)
    
    assert_equal "1", result.id
    assert_equal "Test", result.title
  end

  def test_create_article_with_empty_title
    article_data = { title: "", content: "Content" }
    
    # Gateway should not be called when validation fails
    @mock_gateway.expects(:all).never
    @mock_gateway.expects(:save).never
    
    result = @circuit.create(**article_data)
    
    assert_nil result
  end

  def test_create_article_with_empty_content
    article_data = { title: "Test", content: "" }
    
    # Gateway should not be called when validation fails
    @mock_gateway.expects(:all).never
    @mock_gateway.expects(:save).never
    
    result = @circuit.create(**article_data)
    
    assert_nil result
  end

  def test_create_article_with_nil_values
    article_data = { title: nil, content: "Content" }
    
    @mock_gateway.expects(:all).never
    @mock_gateway.expects(:save).never
    
    result = @circuit.create(**article_data)
    
    assert_nil result
  end

  def test_create_article_with_whitespace_only
    article_data = { title: "   ", content: "Content" }
    
    @mock_gateway.expects(:all).never
    @mock_gateway.expects(:save).never
    
    result = @circuit.create(**article_data)
    
    assert_nil result
  end

  def test_list_articles
    mock_articles = [
      Article.new(id: "1", title: "Article 1", content: "Content 1"),
      Article.new(id: "2", title: "Article 2", content: "Content 2")
    ]
    
    @mock_gateway.expects(:all).returns(mock_articles)
    
    result = @circuit.list
    
    assert_equal 2, result.size
    assert_equal "Article 1", result.first.title
    assert_equal "Article 2", result.last.title
  end

  def test_find_article
    mock_article = Article.new(id: "1", title: "Test Article", content: "Test Content")
    
    @mock_gateway.expects(:find).with("1").returns(mock_article)
    
    result = @circuit.find("1")
    
    assert_equal "1", result.id
    assert_equal "Test Article", result.title
    assert_equal "Test Content", result.content
  end

  def test_find_nonexistent_article
    @mock_gateway.expects(:find).with("999").returns(nil)
    
    result = @circuit.find("999")
    
    assert_nil result
  end

  def test_update_article
    existing_article = Article.new(id: "1", title: "Old Title", content: "Old Content")
    updated_article = Article.new(id: "1", title: "New Title", content: "New Content")
    
    @mock_gateway.expects(:find).with("1").returns(existing_article)
    # Don't expect specific object instance, just any Article with id "1"
    @mock_gateway.expects(:save).with(instance_of(Article)).returns(updated_article)
    
    result = @circuit.update(id: "1", title: "New Title", content: "New Content")
    
    assert_equal "1", result.id
    assert_equal "New Title", result.title
    assert_equal "New Content", result.content
  end

  def test_update_article_with_empty_title
    # No gateway calls should happen when validation fails
    @mock_gateway.expects(:find).never
    @mock_gateway.expects(:save).never
    
    result = @circuit.update(id: "1", title: "", content: "New Content")
    
    assert_nil result
  end

  def test_update_article_with_empty_content
    # No gateway calls should happen when validation fails
    @mock_gateway.expects(:find).never
    @mock_gateway.expects(:save).never
    
    result = @circuit.update(id: "1", title: "New Title", content: "")
    
    assert_nil result
  end

  def test_update_nonexistent_article
    @mock_gateway.expects(:find).with("999").returns(nil)
    @mock_gateway.expects(:save).never
    
    result = @circuit.update(id: "999", title: "New Title", content: "New Content")
    
    assert_nil result
  end

  def test_delete_article
    existing_article = Article.new(id: "1", title: "Test Article", content: "Test Content")
    
    @mock_gateway.expects(:find).with("1").returns(existing_article)
    @mock_gateway.expects(:delete).with("1").returns(true)
    
    result = @circuit.delete("1")
    
    assert_equal true, result
  end

  def test_delete_nonexistent_article
    @mock_gateway.expects(:find).with("999").returns(nil)
    @mock_gateway.expects(:delete).never
    
    result = @circuit.delete("999")
    
    assert_nil result
  end
end