class ErrorHandler
  # 400 - Bad Request
  def self.render_400(exception = nil)
    template_file = File.join(ROOT, 'framework', 'errors', 'templates', '400.html')
    unless File.exist?(template_file)
      msg = exception ? exception.message : "Bad Request"
      return [400, { 'Content-Type' => 'text/html; charset=utf-8' }, ["400 - Bad Request: #{msg}"]]
    end

    body = File.read(template_file)
    body = body.gsub('{{message}}', exception&.message.to_s)
    [400, { 'Content-Type' => 'text/html; charset=utf-8' }, [body]]
  end

  # 401 - Unauthorized
  def self.render_401(exception = nil)
    template_file = File.join(ROOT, 'framework', 'errors', 'templates', '401.html')
    unless File.exist?(template_file)
      msg = exception ? exception.message : "Unauthorized"
      return [401, { 'Content-Type' => 'text/html; charset=utf-8' }, ["401 - Unauthorized: #{msg}"]]
    end

    body = File.read(template_file)
    body = body.gsub('{{message}}', exception&.message.to_s)
    [401, { 'Content-Type' => 'text/html; charset=utf-8' }, [body]]
  end

  # 403 - Forbidden
  def self.render_403(exception = nil)
    template_file = File.join(ROOT, 'framework', 'errors', 'templates', '403.html')
    unless File.exist?(template_file)
      msg = exception ? exception.message : "Forbidden"
      return [403, { 'Content-Type' => 'text/html; charset=utf-8' }, ["403 - Forbidden: #{msg}"]]
    end

    body = File.read(template_file)
    body = body.gsub('{{message}}', exception&.message.to_s)
    [403, { 'Content-Type' => 'text/html; charset=utf-8' }, [body]]
  end

  # 404 - Not Found
  def self.render_404(path)
    template_file = File.join(ROOT, 'framework', 'errors', 'templates', '404.html')
    unless File.exist?(template_file)
      return [404, { 'Content-Type' => 'text/html; charset=utf-8' }, ["404 - Page Not Found"]]
    end

    body = File.read(template_file).gsub('{{path}}', path)
    [404, { 'Content-Type' => 'text/html; charset=utf-8' }, [body]]
  end

  # 500 - Internal Server Error
  def self.render_500(exception)
    template_file = File.join(ROOT, 'framework', 'errors', 'templates', '500.html')
    unless File.exist?(template_file)
      return [500, { 'Content-Type' => 'text/html; charset=utf-8' }, ["500 - Internal Server Error: #{exception.message}"]]
    end

    body = File.read(template_file)
              .gsub('{{message}}', exception.message)
              .gsub('{{backtrace}}', exception.backtrace.first(10).join("<br>"))
    [500, { 'Content-Type' => 'text/html; charset=utf-8' }, [body]]
  end

  # 304 - Not Modified
  def self.render_304
    template_file = File.join(ROOT, 'framework', 'errors', 'templates', '304.html')
    unless File.exist?(template_file)
      return [304, { 'Content-Type' => 'text/html; charset=utf-8' }, ["304 - Not Modified"]]
    end

    body = File.read(template_file)
    [304, { 'Content-Type' => 'text/html; charset=utf-8' }, [body]]
  end
end
