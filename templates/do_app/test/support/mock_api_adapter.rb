# test/support/mock_api_adapter.rb
module MockApiAdapter
  def initialize
    @gateway = MockArticlesGateway.new
    @articles_circuit = ArticlesCircuit.new(@gateway)
  end
  
  def index(env)
    begin
      articles = @articles_circuit.list
      [200, { 'Content-Type' => 'application/json' }, [articles.to_json]]
    rescue => e
      puts "API Error: #{e.message}"
      [500, { 'Content-Type' => 'application/json' }, [{ error: "Internal server error" }.to_json]]
    end
  end
  
  def show(env, id)
    begin
      article = @articles_circuit.find(id)
      if article
        [200, { 'Content-Type' => 'application/json' }, [article.to_json]]
      else
        [404, { 'Content-Type' => 'application/json' }, [{ error: "Article not found" }.to_json]]
      end
    rescue => e
      puts "API Error: #{e.message}"
      [500, { 'Content-Type' => 'application/json' }, [{ error: "Internal server error" }.to_json]]
    end
  end
  
  def create(env)
    request = Rack::Request.new(env)
    begin
      data = JSON.parse(request.body.read)
      article_data = data.transform_keys(&:to_sym)
      article = @articles_circuit.create(**article_data)
      if article
        [201, { 'Content-Type' => 'application/json' }, [article.to_json]]
      else
        [422, { 'Content-Type' => 'application/json' }, [{ error: "Title and content are required" }.to_json]]
      end
    rescue JSON::ParserError
      [400, { 'Content-Type' => 'application/json' }, [{ error: "Invalid JSON" }.to_json]]
    rescue => e
      puts "API Error: #{e.message}"
      [422, { 'Content-Type' => 'application/json' }, [{ error: e.message }.to_json]]
    end
  end
  
  def update(env, id)
    request = Rack::Request.new(env)
    begin
      data = JSON.parse(request.body.read)
      article = @articles_circuit.update(id: id, **data.transform_keys(&:to_sym))
      if article
        [200, { 'Content-Type' => 'application/json' }, [article.to_json]]
      else
        [404, { 'Content-Type' => 'application/json' }, [{ error: "Article not found" }.to_json]]
      end
    rescue JSON::ParserError
      [400, { 'Content-Type' => 'application/json' }, [{ error: "Invalid JSON" }.to_json]]
    rescue => e
      puts "API Update Error: #{e.message}"
      [422, { 'Content-Type' => 'application/json' }, [{ error: e.message }.to_json]]
    end
  end
  
  def delete(env, id)
    begin
      result = @articles_circuit.delete(id)
      if result
        [200, { 'Content-Type' => 'application/json' }, [{ message: "Article deleted successfully" }.to_json]]
      else
        [404, { 'Content-Type' => 'application/json' }, [{ error: "Article not found" }.to_json]]
      end
    rescue => e
      puts "API Error: #{e.message}"
      [500, { 'Content-Type' => 'application/json' }, [{ error: "Internal server error" }.to_json]]
    end
  end
end