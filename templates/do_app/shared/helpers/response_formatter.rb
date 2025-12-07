# shared/helpers/response_formatter.rb
require 'json'

class ResponseFormatter
  def self.json(data, status: 200)
    # Convert data to JSON-serializable format
    json_data = if data.is_a?(Array)
                  data.map { |item| item.respond_to?(:to_h) ? item.to_h : item }
                elsif data.respond_to?(:to_h)
                  data.to_h
                else
                  data
                end
    
    [status, 
     {'Content-Type' => 'application/json'}, 
     [json_data.to_json]]
  end

  def self.html(content, status: 200)
    [status,
     {'Content-Type' => 'text/html; charset=utf-8'}, 
     [content]]
  end
end