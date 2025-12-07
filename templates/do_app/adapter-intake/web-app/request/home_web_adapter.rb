# adapters-intake/web-app/request/home_web_adapter.rb

class HomeWebAdapter
  def initialize
  end

  def home_page(_request)
    metadata = {
      page_title: "Welcome to Hyraft",
      page_description: "Hyraft is a full-stack Ruby web framework that combines high-performance hexagonal architecture with modern reactive frontend."
    }
    #  puts "DEBUG: Metadata: #{metadata}"  # Check if the metadata is correct
    {
      status: 200,
      locals: metadata, 
      display: 'home/home.hyr' 
    }
  end
end
