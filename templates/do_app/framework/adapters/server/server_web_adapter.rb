# framework/adapters/server/server_web_adapter.rb

require_root 'framework/compiler/style_resolver'
require_root 'framework/errors/error_handler'
require_root 'infra/config/error_config' 

class ServerWebAdapter
  def initialize(router = Web)
    @router = router
    # Set up error config with template finder
    ErrorConfig.set_template_finder(method(:find_template_anywhere))
  end

  def call(env)
    req    = Rack::Request.new(env)
    method = env['REQUEST_METHOD']
    path   = env['PATH_INFO']

    resolved = @router.resolve(method, path)

    if resolved
      route, params = resolved
      handler_class, action = route.handler_class, route.action
      handler = handler_class.new
      req.update_param('route_params', params)

      # Call handler
      result = handler.public_send(action, req) || {}
      status = (result[:status] || 200).to_i
      locals = result[:locals] || {}
      view_template = result[:display]

      # EXPLICIT: If a display template is specified, ALWAYS use it
      if view_template
        begin
          body = render_hyraft(view_template, locals)
          return [status, { 'Content-Type' => 'text/html; charset=utf-8' }, [body]]
        rescue StandardError => e
          return handle_error(500, e)
        end
      end

      # Handle redirects
      if result[:status] && (300..399).include?(result[:status].to_i) && result[:headers] && result[:headers]['Location']
        return [result[:status], result[:headers], ['']]
      end

      # If no explicit template, then handle errors
      if status >= 400
        return handle_error(status, nil, path, locals)
      end

      # Success with no template
      return [status, { 'Content-Type' => 'text/html; charset=utf-8' }, ['']]
    else
      # route not found -> 404
      return handle_error(404, nil, path)
    end
  rescue StandardError => e
    return handle_error(500, e)
  end

  private

  # ADD THIS MISSING METHOD
  def handle_error(status, exception = nil, path = nil, locals = {})
    # Check if custom template exists
    if ErrorConfig.custom_template_exists?(status)
      begin
        template_path = ErrorConfig.custom_template_for(status)
        error_locals = ErrorConfig.custom_locals_for(status, path || exception, locals)
        
        body = render_hyraft(template_path, error_locals.merge(locals))
        return [status, { 'Content-Type' => 'text/html; charset=utf-8' }, [body]]
      rescue StandardError => e
        # Fall back to default error handler if custom template fails
        puts "Custom error template failed: #{e.message}"
      end
    end

    # Fall back to default error handler
    dispatch_error_status(status, path, locals.merge(exception: exception))
  end

  # Map status -> ErrorHandler method, allow fallback/defaults
  def dispatch_error_status(status, request_path, locals)
    # prefer explicit methods like render_404, render_401, etc.
    method_name = "render_#{status}"

    if ErrorHandler.respond_to?(method_name)
      case status
      when 404
        return ErrorHandler.public_send(method_name, (locals[:path] || request_path))
      when 304
        return ErrorHandler.public_send(method_name) # usually no placeholders
      when 400, 401, 403
        # pass an Exception-like object when templates expect {{message}}/{{backtrace}}
        exc = locals[:exception] || locals[:error] || StandardError.new(locals[:message].to_s)
        return ErrorHandler.public_send(method_name, exc)
      when 500..599
        exc = locals[:exception] || locals[:error] || StandardError.new(locals[:message].to_s)
        return ErrorHandler.public_send(method_name, exc)
      else
        # Generic: try to call with locals if available
        return ErrorHandler.public_send(method_name, locals) rescue generic_fallback(status, locals)
      end
    end

    # If ErrorHandler has a generic `render(status, options)` method, use it
    if ErrorHandler.respond_to?(:render)
      return ErrorHandler.render(status, locals)
    end

    # final fallback: plain text minimal response
    body = locals[:message] || "HTTP #{status}"
    return [status, { 'Content-Type' => 'text/plain; charset=utf-8' }, [body]]
  end

  # Generic fallback used in rescue above
  def generic_fallback(status, locals)
    if ErrorHandler.respond_to?(:render)
      return ErrorHandler.render(status, locals)
    else
      return [status, { 'Content-Type' => 'text/plain; charset=utf-8' }, [locals[:message] || "HTTP #{status}"]]
    end
  end

  # Render .hyr templates using Hyraft compiler with auto-detect
  def render_hyraft(template_path, locals = {})
    template_key = template_path.gsub(/\.hyr$/, '')
    
    # Use preloader if available
    if defined?(Hyraft::Preloader) && Hyraft::Preloader.template_preloaded?(template_key)
      return Hyraft::Preloader.render_template(template_key, locals)
    end

    # Fallback to file compilation
    template_file = find_template_anywhere(template_path)
    
    unless File.exist?(template_file)
      raise "Template not found: #{template_path}. Searched in all apps under adapter-intake"
    end

    layout_file = File.join(ROOT, 'public', 'index.html')
    compiler = HyraftCompiler.new(layout_file)
    locals.each { |k, v| instance_variable_set("@#{k}", v) }
    compiler.compile(template_file, locals)
  end

  # Search all apps under adapter-intake for the template
  def find_template_anywhere(template_name)
    # Remove .hyr extension if present for flexible matching
    clean_name = template_name.gsub(/\.hyr$/, '')
    
    # Search pattern: adapter-intake/*/display/**/{template_name}.hyr
    search_pattern = File.join(ROOT, 'adapter-intake', '*', 'display', '**', "#{clean_name}.hyr")
    matching_files = Dir.glob(search_pattern)
    
    if matching_files.any?
      # Return the first match (you could add priority logic here)
      return matching_files.first
    else
      # Show available templates for better debugging
      available_templates = Dir.glob(File.join(ROOT, 'adapter-intake', '*', 'display', '**', '*.hyr'))
      # puts "DEBUG: Available templates:"
     # available_templates.each { |f| puts "  - #{f.gsub(ROOT + '/', '')}" }
      
      raise "Template '#{template_name}' not found in any app under adapter-intake"
    end
  end

  def compile_styles(hyr_file_path, style_src)
    Compiler::StyleResolver.resolve_style_path(style_src, from: hyr_file_path)
  end

  # Optional: Keep alias for backward compatibility if needed
  alias_method :render_hyraft_with_preloader, :render_hyraft
end