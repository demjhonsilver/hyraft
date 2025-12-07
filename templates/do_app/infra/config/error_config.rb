# infra/config/error_config.rb

module ErrorConfig

  CUSTOM_ERROR_TEMPLATES = {
    404 => '', # web-app/display/ add this: pages/errors/404.hyr
    500 => '', # pages/errors/500.hyr
    422 => '', #  pages/errors/422.hyr
    401 => '', # pages/errors/401.hyr
    403 => '' # pages/errors/403.hyr
  }

  CUSTOM_ERROR_LOCALS = {
    404 => ->(path, locals) { 
      { 
        path: path,
        message: "The page you're looking for doesn't exist.",
        suggestions: [
          "Check the URL for typos",
          "Go back to the homepage", 
        ]
      }
    },
    500 => ->(exception, locals) {
      {
        error: exception.message,
        backtrace: exception.backtrace.first(5),
        message: "Something went wrong on our end."
      }
    },
    422 => ->(exception, locals) {
      {
        error: exception.message,
        message: "We couldn't process your request."
      }
    }
  }

  # Check if custom template exists for a status code
  def self.custom_template_exists?(status)
    template_path = CUSTOM_ERROR_TEMPLATES[status]
    return false unless template_path
    
    begin
      template_file = find_template_anywhere(template_path)
      File.exist?(template_file)
    rescue
      false
    end
  end

  # Get custom template path for status code
  def self.custom_template_for(status)
    CUSTOM_ERROR_TEMPLATES[status]
  end

  # Get custom locals for status code
  def self.custom_locals_for(status, *args)
    return {} unless CUSTOM_ERROR_LOCALS[status]
    
    CUSTOM_ERROR_LOCALS[status].call(*args)
  end

  # Helper method to find templates (delegates to WebAdapter)
  def self.find_template_anywhere(template_name)
    # This will be set by WebAdapter
    if defined?(@template_finder)
      @template_finder.call(template_name)
    else
      # Fallback for when not called from WebAdapter
      search_pattern = File.join(ROOT, 'adapter-intake', '*', 'display', '**', "#{template_name.gsub(/\.hyr$/, '')}.hyr")
      Dir.glob(search_pattern).first
    end
  end

  # Set template finder from WebAdapter
  def self.set_template_finder(finder)
    @template_finder = finder
  end
end