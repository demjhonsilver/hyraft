
require 'digest'

module Hyraft
  class PreloadedStatic
    def initialize(app, options = {})
      @app = app
      @urls = options[:urls] || ["/styles", "/css", "/images", "/js", "/favicon.ico"]
    end

    def call(env)
      path = env['PATH_INFO']
      
      # Check if this is a static asset we should handle
      if @urls.any? { |url| path.start_with?(url) }
        serve_preloaded_asset(path)
      else
        @app.call(env)
      end
    end

    private

    def serve_preloaded_asset(path)
      # Normalize path (remove leading slash)
      asset_path = path.start_with?('/') ? path[1..-1] : path
      
      if Hyraft::AssetPreloader.asset_preloaded?(asset_path)
        # ULTRA FAST: Serve from memory
        asset_data = Hyraft::AssetPreloader.serve_asset(asset_path)
        
        headers = {
          'Content-Type' => asset_data[:content_type],
          'Content-Length' => asset_data[:compressed_size].to_s,
          'Cache-Control' => 'public, max-age=86400',
          'ETag' => Digest::MD5.hexdigest(asset_data[:compressed])
        }
        
        [200, headers, [asset_data[:compressed]]]
      else
        # Fallback to original request
        @app.call(env)
      end
    end
  end
end