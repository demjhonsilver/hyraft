# lib/hyraft/compiler/renderer.rb
require_relative 'javascript_library'
require_relative 'html_purifier'  

module Hyraft
  module Compiler
    class HyraftRenderer
      include HtmlPurifier


      def initialize(obfuscation_method: :multi_layer)
        @obfuscation_method = obfuscation_method
      end

      def render(layout, parsed, locals = {})
        locals&.each { |k, v| instance_variable_set("@#{k}", v) }
        
        # Initialize required JS storage
        @required_js = []
        
        # Process requires from metadata FIRST
        if parsed[:metadata]
          metadata_content = parsed[:metadata].to_s

          # Extract and process requires
          requires = extract_requires(metadata_content)
          requires.each { |file_path| load_required_file(file_path) }
          # Remove requires from metadata for final rendering
          parsed[:metadata] = remove_requires(metadata_content)
        end

        if parsed[:transmuter]
          transmuter_code = parsed[:transmuter]
          processed_transmuter = convert_html_tags(transmuter_code)
          instance_eval(processed_transmuter)
        end

        content = render_displayer(parsed[:displayer].to_s)
        styles = (parsed[:styles] || []).map { |s| "<link rel='stylesheet' href='#{s}'>" }.join
        
        # Combine required JS with main manifestor - IN CORRECT ORDER
        all_js = []
        all_js += @required_js if @required_js  # Required libraries first
        
        # Add main manifestor code (no obfuscation for app code by default)
        if parsed[:manifestor] && !parsed[:manifestor].strip.empty?
          all_js << parsed[:manifestor]
        end
        
        # Combine all JavaScript
        js_content = all_js.join("\n")
        js = js_content.strip.empty? ? '' : "<script>#{js_content}</script>"
        
        metas = render_displayer(parsed[:metadata].to_s)

        result = layout.dup
        inject_title(result, find_title(metas))
        inject_metas(result, metas)
        result.gsub!('<hyraft styles="css">', styles)
             .gsub!('<hyraft content="hyraft">', content)
             .gsub!('<hyraft script="javascript">', js)
        result
      end


      



      
      private

      def extract_requires(metadata_content)
        requires = []
        metadata_content.scan(/<require\s+file="([^"]+)"\s*\/>/) do |match|
          requires << match.first
        end
        requires
      end

      def remove_requires(metadata_content)
        metadata_content.gsub(/<require\s+file="[^"]+"\s*\/>/, '')
      end

      def load_required_file(relative_path)
        # Clean the library name (remove .hyr extension if present)
        clean_name = relative_path.gsub(/\.hyr$/, '')
        
        # Get the obfuscated library code
        js_code = JavaScriptLibrary.get(clean_name, obfuscation_method: @obfuscation_method)
        
        if js_code
          @required_js ||= []
          @required_js << js_code
        else
          # If not found in JavaScriptLibrary, fall back to file system search
          full_path = find_required_file_anywhere(relative_path)
          
          if full_path && File.exist?(full_path)
            content = File.read(full_path)
            parsed_required = parse_content(content)
            
            # Process transmuter from required files (for Ruby code)
            if parsed_required[:transmuter] && !parsed_required[:transmuter].strip.empty?
              required_transmuter = convert_html_tags(parsed_required[:transmuter])
              instance_eval(required_transmuter)
            end
            
            # Store manifestor content from required files (for JavaScript)
            if parsed_required[:manifestor] && !parsed_required[:manifestor].strip.empty?
              @required_js ||= []
              # Apply obfuscation to file-based libraries too
              file_js = parsed_required[:manifestor]
              obfuscated_file_js = case @obfuscation_method
                                  when :split_and_reassemble
                                    JavaScriptObfuscator.split_and_reassemble(file_js)
                                  when :multi_layer
                                    JavaScriptObfuscator.multi_layer_obfuscation(file_js)
                                  else
                                    file_js
                                  end
              @required_js << obfuscated_file_js
            end
          else
            puts "WARNING: Required file not found: #{relative_path}"
            puts "Available built-in libraries: #{JavaScriptLibrary.available_libraries.join(', ')}"
          end
        end
      end

      def find_required_file_anywhere(relative_path)
        # Remove .hyr extension if present
        clean_path = relative_path.gsub(/\.hyr$/, '')
        
        # Search pattern: adapter-intake/*/display/**/{relative_path}.hyr
        search_pattern = File.join(ROOT, 'adapter-intake', '*', 'display', '**', "#{clean_path}.hyr")
        matching_files = Dir.glob(search_pattern)
        
        matching_files.first # Return first match
      end

      def parse_content(content)
        sections = {
          metadata: content[/<metadata[^>]*>(.*?)<\/metadata>/m, 1],
          displayer: content[/<displayer[^>]*>(.*?)<\/displayer>/m, 1],
          transmuter: content[/<transmuter[^>]*>(.*?)<\/transmuter>/m, 1],
          manifestor: content[/<manifestor[^>]*>(.*?)<\/manifestor>/m, 1],
          styles: content.scan(/<style\s+src="([^"]+)"\s*\/?>/).flatten 
        }
        sections
      end


      

      def convert_html_tags(code)
        code.gsub(/<html>([\s\S]*?)<\/html>/) do |match|
          content = $1.strip
          
          lines = content.split("\n")
          indented_content = lines.map { |line| "  #{line}" }.join("\n")
          "<<~HTML\n#{indented_content}\nHTML"
        end
      end

      def render_displayer(html)
        html.gsub(/\[\.\s*(\w+)\s*\.\]/) { respond_to?($1) ? send($1).to_s : "[.#{$1}.]" }
            .gsub(/<([\w-]+)(\s+[^>]*)?\s*\/>/) do |match|
              tag = $1
              attr_str = $2
              render_component(tag, attr_str)
            end
      end

      def render_component(tag, attr_str)
        method_name = "display_#{tag.tr('-', '_')}"
        attrs = parse_attributes(attr_str.to_s)
        
        if respond_to?(method_name)
          return send(method_name, **attrs)
        end
        
        attr_html = attrs.map { |k,v| "#{k}='#{v}'" }.join(' ')
        "<div class='#{tag}' #{attr_html}>#{attrs[:name] || tag}</div>"
      end

      def parse_attributes(str) 
        return {} if str.nil? || str.empty?
        str.scan(/(\w+)="(.*?)"/).to_h { |k,v| [k.to_sym, v] }
      end

      def find_title(metas)
        metas[/\<title\>(.*?)\<\/title\>/m, 1] || 
        (instance_variable_defined?(:@page_title) && @page_title) ||
        (page_title if respond_to?(:page_title))
      end

      def inject_title(result, title)
        return unless title
        result.sub!(/<title>.*<\/title>/m, "<title>#{title}</title>") || 
        result.sub!('</head>', "  <title>#{title}</title>\n</head>")
      end

      def inject_metas(result, metas)
        return if metas.empty?
        
        if result.include?('<hyraft meta="tags">')
          result.gsub!('<hyraft meta="tags">', metas)
        elsif result.include?('<hyraft styles="css">')
          result.sub!('<hyraft styles="css">', "#{metas}\n<hyraft styles=\"css\">")
        else
          result.sub!('</head>', "#{metas}\n</head>")
        end
      end
    end
  end
end