require_relative "./../../../test_helper"

class ArticleTest < Minitest::Test
  def test_initialization
    article = Article.new(
      id: "1",
      title: "Test Article",
      content: "Test content"
    )
    
    assert_equal "1", article.id
    assert_equal "Test Article", article.title
    assert_equal "Test content", article.content
    assert_equal :draft, article.status
  end

  def test_to_hash
    article = Article.new(
      id: "1",
      title: "Test",
      content: "Content"
    )
    
    hash = article.to_hash
    
    assert_equal "1", hash[:id]
    assert_equal "Test", hash[:title]
    assert_equal "Content", hash[:content]
  end

  def test_publish
    article = Article.new(id: "1", title: "Test", content: "Content")
    article.publish
    
    assert_equal :published, article.status
  end
end
