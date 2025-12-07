# lib/hyraft/boot/asset_preloader.rb
module Hyraft
  module AssetPreloader
    COLORS = {
      green:  "\e[32m",
      cyan:   "\e[36m", 
      yellow: "\e[33m",
      red:    "\e[31m",
      orange: "\e[38;5;214m",  
      blue:   "\e[34m",     
      lightblue: "\e[94m",   
      reset:  "\e[0m"
    }

    @preloaded_assets = {}
    @stats = {
      total_assets: 0,
      total_bytes: 0,
      compressed_bytes: 0,
      load_time: 0.0
    }

    def self.preload_assets(public_path)
      puts "#{COLORS[:green]} Hyraft Asset Preloader: Scanning for assets...#{COLORS[:reset]}"
      
      start_time = Time.now
      assets_found = discover_assets(public_path)
      
      puts "Found #{assets_found.size} asset files"
      
      assets_found.each do |asset_path|
        preload_asset(asset_path, public_path)
      end
      
      @stats[:load_time] = Time.now - start_time
      print_stats
    end

    def self.discover_assets(public_path)
      return [] unless File.exist?(public_path)
      
      assets = []
      
      # Look for assets in common locations
      asset_patterns = [
        "styles/css/**/*.css",
        "css/**/*.css", 
        "images/**/*.{jpg,jpeg,png,gif,svg,webp,ico}",
        "js/**/*.js",
        "favicon.ico"
      ]
      
      asset_patterns.each do |pattern|
        full_pattern = File.join(public_path, pattern)
        assets += Dir.glob(full_pattern)
      end
      
      assets.sort
    end

    def self.preload_asset(asset_path, public_path)
      relative_path = asset_path.sub(public_path + '/', '')
      
      begin
        content = File.read(asset_path, mode: 'rb')
        compressed = compress_asset(content, File.extname(asset_path))
        
        @preloaded_assets[relative_path] = {
          content: content,
          compressed: compressed,
          size: content.bytesize,
          compressed_size: compressed.bytesize,
          mtime: File.mtime(asset_path),
          content_type: content_type_for(asset_path)
        }
        
        @stats[:total_assets] += 1
        @stats[:total_bytes] += content.bytesize
        @stats[:compressed_bytes] += compressed.bytesize
        
        compression_ratio = ((1 - compressed.bytesize.to_f / content.bytesize) * 100).round(2)
        
        puts "  #{COLORS[:green]}✓#{COLORS[:reset]} #{COLORS[:lightblue]}#{relative_path}#{COLORS[:reset]} " \
             "(#{COLORS[:yellow]}#{(content.bytesize / 1024.0).round(2)} KB#{COLORS[:reset]} → " \
             "#{COLORS[:cyan]}#{(compressed.bytesize / 1024.0).round(2)} KB#{COLORS[:reset]} " \
             "#{COLORS[:green]}#{compression_ratio}%#{COLORS[:reset]})"
             
      rescue => e
        puts "  #{COLORS[:red]}✗#{COLORS[:reset]} #{COLORS[:cyan]}#{relative_path}#{COLORS[:reset]} " \
             "#{COLORS[:red]}Error: #{e.message}#{COLORS[:reset]}"
      end
    end

    def self.compress_asset(content, extname)
      case extname.downcase
      when '.css'
        compress_css(content)
      when '.js'
        compress_js(content)
      else
        content
      end
    end

    def self.compress_css(css)
      css.gsub(/\/\*.*?\*\//m, '')
         .gsub(/\s+/, ' ')
         .gsub(/;\s*}/, '}')
         .gsub(/\s*{\s*/, '{')
         .gsub(/\s*}\s*/, '}')
         .gsub(/:\s+/, ':')
         .gsub(/,\s+/, ',')
         .strip
    end

    def self.compress_js(js)
      js.gsub(/\/\/.*?$/, '')
        .gsub(/\/\*.*?\*\//m, '')
        .gsub(/\s+/, ' ')
        .gsub(/\s*([=+\-\/*{}()\[\],;:])\s*/, '\1')  
        .strip
    end

    def self.content_type_for(file_path)
      case File.extname(file_path).downcase
      when '.css' then 'text/css'
      when '.js' then 'application/javascript'
      when '.jpg', '.jpeg' then 'image/jpeg'
      when '.png' then 'image/png'
      when '.gif' then 'image/gif'
      when '.svg' then 'image/svg+xml'
      when '.webp' then 'image/webp'
      when '.ico' then 'image/x-icon'
      else 'application/octet-stream'
      end
    end

    def self.get_asset(asset_path)
      @preloaded_assets[asset_path]
    end

    def self.asset_preloaded?(asset_path)
      @preloaded_assets.key?(asset_path)
    end

    def self.serve_asset(asset_path)
      return nil unless asset_preloaded?(asset_path)
      get_asset(asset_path)
    end

    def self.stats
      @stats.dup
    end

    private

    def self.print_stats
      puts "\n#{COLORS[:green]}Asset Preload Statistics:#{COLORS[:reset]}"
      puts "   #{COLORS[:cyan]}Assets:#{COLORS[:reset]} #{@stats[:total_assets]}"
      puts "   #{COLORS[:cyan]}Original Size:#{COLORS[:reset]} #{(@stats[:total_bytes] / 1024.0).round(2)} KB" 
      puts "   #{COLORS[:cyan]}Compressed Size:#{COLORS[:reset]} #{(@stats[:compressed_bytes] / 1024.0).round(2)} KB"
      puts "   #{COLORS[:cyan]}Total Savings:#{COLORS[:reset]} #{((@stats[:total_bytes] - @stats[:compressed_bytes]) / 1024.0).round(2)} KB"
      puts "   #{COLORS[:cyan]}Load Time:#{COLORS[:reset]} #{@stats[:load_time].round(3)}s"
      puts "   #{COLORS[:cyan]}Memory:#{COLORS[:reset]} #{memory_usage} MB"
      puts "   #{COLORS[:cyan]}Status:#{COLORS[:reset]} #{COLORS[:green]}ASSETS PRELOADED#{COLORS[:reset]}\n\n"
    end

    def self.memory_usage
      if Gem.win_platform?
        # Windows (no `ps -o rss=`)
        get_windows_memory
      else
        # Linux/Mac
        (`ps -o rss= -p #{Process.pid}`.to_i / 1024.0).round(2)
      end
    end

    def self.get_windows_memory
      memory_kb = `tasklist /FI "PID eq #{Process.pid}" /FO CSV /NH`
                    .split(",")[4].to_s.gsub('"','').gsub(/[^0-9]/, '').to_i
      (memory_kb / 1024.0).round(2)
    end
    
  end
end