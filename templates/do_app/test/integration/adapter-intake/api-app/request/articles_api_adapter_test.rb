# In test/integration/adapter-intake/api-app/request/articles_api_adapter_test.rb

def test_create_article
  post '/api/articles', 
    { title: "New API Article", content: "API Content" }.to_json,
    { 'CONTENT_TYPE' => 'application/json' }
  
  assert_equal 201, last_response.status
  response = JSON.parse(last_response.body)
  
  # Debug the actual response
  puts "DEBUG: Create response: #{response}"
  
  assert response["id"], "Article should have an ID. Response: #{response}"
  assert_equal "New API Article", response["title"]
  assert_equal "API Content", response["content"]
end

def test_get_article
  # Create test article through the API first
  post '/api/articles', 
    { title: "Single Article", content: "Single Content" }.to_json,
    { 'CONTENT_TYPE' => 'application/json' }
  
  assert_equal 201, last_response.status
  created_article = JSON.parse(last_response.body)
  puts "DEBUG: Created article: #{created_article}"
  
  get "/api/articles/#{created_article['id']}"
  
  puts "DEBUG: Get response status: #{last_response.status}"
  puts "DEBUG: Get response body: #{last_response.body}"
  
  assert_equal 200, last_response.status
  response = JSON.parse(last_response.body)
  assert_equal "Single Article", response["title"]
  assert_equal "Single Content", response["content"]
end

def test_update_article
  # Create article first through the API
  post '/api/articles', 
    { title: "Original", content: "Original Content" }.to_json,
    { 'CONTENT_TYPE' => 'application/json' }
  
  assert_equal 201, last_response.status
  created_article = JSON.parse(last_response.body)
  puts "DEBUG: Created article for update: #{created_article}"

  put "/api/articles/#{created_article['id']}",
    { title: "Updated", content: "Updated Content" }.to_json,
    { 'CONTENT_TYPE' => 'application/json' }
  
  puts "DEBUG: Update response status: #{last_response.status}"
  puts "DEBUG: Update response body: #{last_response.body}"
  
  assert_equal 200, last_response.status
  response = JSON.parse(last_response.body)
  assert_equal "Updated", response["title"]
  assert_equal "Updated Content", response["content"]
end