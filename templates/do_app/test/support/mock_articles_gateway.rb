# test/support/mock_articles_gateway.rb
class MockArticlesGateway
  def initialize
    @storage = {}
    @next_id = 1
  end

  def all
    @storage.values.sort_by { |a| a.id.to_i }
  end

  def find(id)
    @storage[id.to_s]
  end

  def save(article)
    # Ensure the article has proper timestamps
    current_time = Time.now
    if article.created_at.nil?
      article.created_at = current_time
    end
    article.updated_at = current_time
    
    if article.id.nil?
      article.id = @next_id.to_s
      @next_id += 1
    end
    
    @storage[article.id] = article
    article
  end

  def delete(id)
    !!@storage.delete(id.to_s)
  end

  def clear
    @storage.clear
    @next_id = 1
  end
end