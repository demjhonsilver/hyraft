# lib/hyraft/compiler/javascript_obfuscator.rb
require 'json'

module Hyraft
  module Compiler
    class JavaScriptObfuscator
      class << self
        # Method 4: Split and Reassemble
        def split_and_reassemble(js_code, parts: 8)
          return '' unless js_code && !js_code.strip.empty?
          
          # Calculate chunk size
          chunk_size = (js_code.length.to_f / parts).ceil
          # Split into chunks
          chunks = js_code.chars.each_slice(chunk_size).map(&:join)
          
          # Convert to JSON for JavaScript array
          chunks_js = chunks.to_json
          
          <<~JAVASCRIPT
          (function(){
            try {
              var c=#{chunks_js};
              var s=c.join('');
              var e=document.createElement('script');
              e.textContent=s;
              document.head.appendChild(e);
            } catch(err) {
              console.error('Script load failed:', err);
            }
          })();
          JAVASCRIPT
        end

        # Method 10: Multi-Layer Obfuscation
        def multi_layer_obfuscation(js_code)
          return '' unless js_code && !js_code.strip.empty?
          
          obfuscated = js_code.dup
          
          # Layer 1: Remove comments and extra whitespace
          obfuscated = remove_comments_and_whitespace(obfuscated)
          
          # Layer 2: Safe variable renaming (EXCLUDE neonPulse)
          obfuscated = rename_variables(obfuscated)
          
          # Layer 3: String obfuscation
          obfuscated = obfuscate_strings(obfuscated)
          
          # Layer 4: Number obfuscation
          obfuscated = obfuscate_numbers(obfuscated)
          
          # Layer 5: Split into chunks and reassemble
          final_js = split_and_reassemble(obfuscated, parts: 6)
          
          final_js
        end
        
        private
        
        def remove_comments_and_whitespace(code)
          # Remove block comments
          code.gsub!(/\/\*[\s\S]*?\*\//, '')
          # Remove line comments
          code.gsub!(/\/\/[^\n\r]*/, '')
          # Collapse multiple whitespace
          code.gsub!(/\s+/, ' ')
          # Remove spaces around operators
          code.gsub!(/\s*([=+\-*\/&|^!<>?{}();:,])\s*/, '\1')
          # Remove multiple semicolons
          code.gsub!(/;\s*;/, ';')
          code.strip
        end
        
        def rename_variables(code)
          # Safe renaming - EXCLUDE neonPulse from renaming
          renames = {
            'NeonPulse' => 'NP',           # Rename class internally
            # 'neonPulse' => 'np',         # DON'T rename the global instance
            'signalName' => 'sN', 
            'initialValue' => 'iV',
            'element' => 'el',
            'property' => 'pr',
            'formData' => 'fD',
            'callback' => 'cb',
            'handler' => 'hd',
            'processor' => 'pc',
            'action' => 'ac',
            'event' => 'ev'
          }
          
          renames.each do |original, replacement|
            code.gsub!(/\b#{original}\b/, replacement)
          end
          
          code
        end
        
        def obfuscate_strings(code)
          # Obfuscate double-quoted strings
          code.gsub!(/"([^"\\]*(\\.[^"\\]*)*)"/) do |match|
            content = $1
            # Mix of hex and unicode escapes
            obfuscated_content = content.chars.map.with_index { |c, i| 
              if i % 3 == 0
                "\\x#{c.ord.to_s(16)}"
              elsif i % 3 == 1
                "\\u#{c.ord.to_s(16).rjust(4, '0')}"
              else
                c
              end
            }.join
            "\"#{obfuscated_content}\""
          end
          
          code
        end
        
        def obfuscate_numbers(code)
          # Convert some numbers to expressions
          code.gsub!(/\b(\d+)\b/) do |match|
            num = $1.to_i
            if num > 5 && num < 100
              case rand(4)
              when 0 then "(#{num - 1} + 1)"
              when 1 then "(#{num * 2} / 2)"
              when 2 then "(#{num} * 1)"
              when 3 then "0x#{num.to_s(16)}"
              else match
              end
            else
              match
            end
          end
          
          code
        end
      end
    end
  end
end