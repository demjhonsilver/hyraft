# framework/boot/preloader.rb - Complete fixed version
module Hyraft
  module Preloader
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

    @preloaded_templates = {}
    @layout_content = nil
    @stats = { 
      total_templates: 0, 
      total_bytes: 0,
      compiled_bytes: 0,
      load_time: 0.0
    }

    def self.preload_templates
      puts "#{COLORS[:green]} Hyraft Preloader: Scanning for templates...#{COLORS[:reset]}"
      
      start_time = Time.now
      
      # Load layout first
      layout_file = File.join(ROOT, 'public', 'index.html')
      @layout_content = File.read(layout_file) if File.exist?(layout_file)
      
      templates_found = discover_templates
      puts "Found #{templates_found.size} template files"
      
      templates_found.each do |file_path|
        preload_template(file_path)
      end
      
      @stats[:load_time] = Time.now - start_time
      print_stats
    end

    def self.discover_templates
      Dir.glob(File.join('adapter-intake', '**', '*.hyr')).sort
    end

    def self.preload_template(file_path)
      template_key = file_path
        .delete_prefix('adapter-intake/')
        .sub(/\.hyr$/, '')
      
      begin
        content = File.read(file_path)
        sections = extract_sections(content)
        
        # ONLY pre-compile templates WITHOUT transmuter code (pure HTML templates)
        compiled_html = nil
        compile_success = false
        compile_error = nil
        
        if @layout_content && sections[:transmuter].to_s.strip.empty?
          begin
            # Only compile templates that don't have Ruby code in transmuter
            renderer = Hyraft::Compiler::HyraftRenderer.new
            
            # For pure HTML templates, we can safely compile with empty locals
            # The [.variable.] placeholders will remain as-is for runtime replacement
            compiled_html = renderer.render(@layout_content.dup, sections, {})
            compile_success = true
            
          rescue => e
            compile_error = e.message
          end
        else
          compile_error = "has transmuter code" if sections[:transmuter] && !sections[:transmuter].empty?
        end
        
        @preloaded_templates[template_key] = {
          sections: sections,
          compiled_html: compiled_html,
          compile_success: compile_success,
          compile_error: compile_error,
          bytesize: content.bytesize,
          compiled_bytes: compiled_html&.bytesize || 0,
          mtime: File.mtime(file_path),
          full_path: file_path
        }
        
        @stats[:total_templates] += 1
        @stats[:total_bytes] += content.bytesize
        @stats[:compiled_bytes] += compiled_html&.bytesize || 0
        
        if compile_success
          puts "  #{COLORS[:green]}✓#{COLORS[:reset]} #{COLORS[:lightblue]}#{template_key}#{COLORS[:reset]}#{COLORS[:orange]}.hyr#{COLORS[:reset]} (#{COLORS[:yellow]}#{(compiled_html.bytesize / 1024.0).round(2)} KB#{COLORS[:reset]})"
        elsif compile_error == "has transmuter code"
          puts "  #{COLORS[:blue]}ℹ#{COLORS[:reset]} #{COLORS[:lightblue]}#{template_key}#{COLORS[:reset]}#{COLORS[:orange]}.hyr#{COLORS[:reset]} (#{COLORS[:cyan]}dynamic template#{COLORS[:reset]})"
        else
          puts "  #{COLORS[:yellow]}⚠#{COLORS[:reset]} #{COLORS[:lightblue]}#{template_key}#{COLORS[:reset]}#{COLORS[:orange]}.hyr#{COLORS[:reset]} (#{COLORS[:red]}sections only#{COLORS[:reset]})"
        end
             
      rescue => e
        puts "  #{COLORS[:red]}✗#{COLORS[:reset]} #{COLORS[:cyan]}#{template_key}#{COLORS[:reset]}#{COLORS[:green]}.hyr#{COLORS[:reset]} #{COLORS[:red]}Error: #{e.message}#{COLORS[:reset]}"
      end
    end

    def self.get_template(template_key)
      @preloaded_templates[template_key]
    end

    def self.template_preloaded?(template_key)
      @preloaded_templates.key?(template_key)
    end

    def self.render_template(template_key, locals = {})
      return "<h1>Template not found: #{template_key}</h1>" unless template_preloaded?(template_key)
      
      template_data = get_template(template_key)
      
      # ULTRA FAST PATH: Use pre-compiled HTML (only for templates without transmuter)
      if template_data[:compiled_html] && template_data[:compile_success]
        return apply_locals_to_compiled(template_data[:compiled_html].dup, locals)
      end
      
      # FAST PATH: Use preloaded sections with HyraftRenderer (for dynamic templates)
      layout_file = File.join(ROOT, 'public', 'index.html')
      layout_content = File.read(layout_file) if File.exist?(layout_file)
      
      renderer = Hyraft::Compiler::HyraftRenderer.new
      renderer.render(layout_content, template_data[:sections], locals)
    end

    # FAST: Apply locals to pre-compiled HTML (only for placeholders, no Ruby execution)
    def self.apply_locals_to_compiled(compiled_html, locals)
      return compiled_html if locals.empty?
      
      # Simple string replacement for [.variable.] placeholders
      locals.each do |key, value|
        placeholder = "[.#{key}.]"
        compiled_html = compiled_html.gsub(placeholder, value.to_s)
      end
      compiled_html
    end

    def self.stats
      @stats.dup
    end

    private

    def self.extract_sections(content)
      {
        metadata: extract_section(content, 'metadata'),
        displayer: extract_section(content, 'displayer'), 
        transmuter: extract_section(content, 'transmuter'),
        manifestor: extract_section(content, 'manifestor'),
        styles: extract_styles(content)
      }
    end

    def self.extract_section(content, section_name)
      match = content.match(/<#{section_name}.*?>(.*?)<\/#{section_name}>/m)
      match ? match[1].strip : ''
    end

    def self.extract_styles(content)
      content.scan(/<style[^>]*href="([^"]*)"/).flatten
    end

    def self.print_stats
      compiled_count = @preloaded_templates.count { |_, t| t[:compile_success] }
      dynamic_count = @preloaded_templates.count { |_, t| t[:compile_error] == "has transmuter code" }
      sections_count = @preloaded_templates.count - compiled_count - dynamic_count
      
      puts "\n#{COLORS[:green]}Preload Statistics:#{COLORS[:reset]}"
      puts "   #{COLORS[:cyan]}Templates:#{COLORS[:reset]} #{@stats[:total_templates]} (#{compiled_count} pre-compiled, #{dynamic_count} dynamic, #{sections_count} sections only)"
      puts "   #{COLORS[:cyan]}Source Size:#{COLORS[:reset]} #{(@stats[:total_bytes] / 1024.0).round(2)} KB" 
      puts "   #{COLORS[:cyan]}Compiled Size:#{COLORS[:reset]} #{(@stats[:compiled_bytes] / 1024.0).round(2)} KB" 
      puts "   #{COLORS[:cyan]}Load Time:#{COLORS[:reset]} #{@stats[:load_time].round(3)}s"
      puts "   #{COLORS[:cyan]}Memory:#{COLORS[:reset]} #{memory_usage} MB"
      
      if compiled_count > 0
        puts "   #{COLORS[:cyan]}Status:#{COLORS[:reset]} #{COLORS[:green]}PARTIALLY PRE-COMPILED#{COLORS[:reset]}\n\n"
      else
        puts "   #{COLORS[:cyan]}Status:#{COLORS[:reset]} #{COLORS[:yellow]}SECTIONS ONLY#{COLORS[:reset]}\n\n"
      end
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