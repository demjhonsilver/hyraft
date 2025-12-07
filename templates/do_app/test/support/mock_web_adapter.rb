# test/support/mock_web_adapter.rb
module MockWebAdapter
  def initialize
    @gateway = MockArticlesGateway.new
    @articles_circuit = ArticlesCircuit.new(@gateway)
  end
  
  def index(request)
    begin
      articles = @articles_circuit.list
      {
        status: 200,
        display: 'pages/articles/index.hyr',
        locals: { articles: articles }
      }
    rescue => e
      puts "Web Adapter Error: #{e.message}"
      {
        status: 500,
        display: 'pages/error.hyr',
        locals: { error: "Internal server error" }
      }
    end
  end
  
  def show(request, id)
    begin
      article = @articles_circuit.find(id)
      if article
        {
          status: 200,
          display: 'pages/articles/show.hyr',
          locals: { article: article }
        }
      else
        {
          status: 404,
          display: 'pages/error.hyr',
          locals: { error: "Article not found" }
        }
      end
    rescue => e
      puts "Web Adapter Error: #{e.message}"
      {
        status: 500,
        display: 'pages/error.hyr',
        locals: { error: "Internal server error" }
      }
    end
  end
  
  def new(request)
    {
      status: 200,
      display: 'pages/articles/new.hyr',
      locals: { article: Article.new }
    }
  end
  
  def edit(request, id)
    begin
      article = @articles_circuit.find(id)
      if article
        {
          status: 200,
          display: 'pages/articles/edit.hyr',
          locals: { article: article }
        }
      else
        {
          status: 404,
          display: 'pages/error.hyr',
          locals: { error: "Article not found" }
        }
      end
    rescue => e
      puts "Web Adapter Error: #{e.message}"
      {
        status: 500,
        display: 'pages/error.hyr',
        locals: { error: "Internal server error" }
      }
    end
  end
end