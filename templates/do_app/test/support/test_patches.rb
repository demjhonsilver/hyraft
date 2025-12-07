# test/support/test_patches.rb
puts "Applying test patches for TEST_NO_DB=1..."

# Patch Article for proper JSON serialization
class Article
  def to_json(*args)
    to_hash.to_json(*args)
  end
  
  def to_hash
    {
      id: id,
      title: title,
      content: content,
      status: status,
      created_at: created_at,
      updated_at: updated_at
    }.compact
  end
end

# Redefine adapters to use MockArticlesGateway
if defined?(ArticlesApiAdapter)
  require_relative 'mock_api_adapter'
  ArticlesApiAdapter.prepend(MockApiAdapter)
  puts "✓ Patched ArticlesApiAdapter"
end

if defined?(ArticlesWebAdapter)
  require_relative 'mock_web_adapter'  
  ArticlesWebAdapter.prepend(MockWebAdapter)
  puts "✓ Patched ArticlesWebAdapter"
end