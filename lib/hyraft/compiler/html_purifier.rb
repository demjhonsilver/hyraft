# lib/hyraft/compiler/html_purifier.rb
module Hyraft
  module Compiler
    module HtmlPurifier
      # Purifies HTML content by escaping dangerous characters to prevent XSS attacks
      # Usage: purify_html(user_input) - makes any string safe for HTML output
      def purify_html(unsafe)
        return '' unless unsafe
        unsafe.to_s
          .gsub(/&/, "&amp;")
          .gsub(/</, "&lt;")
          .gsub(/>/, "&gt;")
          .gsub(/"/, "&quot;")
          .gsub(/'/, "&#039;")
      end
      
      # Alias for purify_html for different use cases
      def escape_html(unsafe)
        purify_html(unsafe)
      end
      
      # Additional HTML safety methods
      def purify_html_attribute(unsafe)
        return '' unless unsafe
        unsafe.to_s
          .gsub(/&/, "&amp;")
          .gsub(/</, "&lt;")
          .gsub(/>/, "&gt;")
          .gsub(/"/, "&quot;")
          .gsub(/'/, "&#x27;")
          .gsub(/\//, "&#x2F;")
      end
      
      def purify_javascript(unsafe)
        return '' unless unsafe
        unsafe.to_s
          .gsub(/\\/, "\\\\")
          .gsub(/'/, "\\'")
          .gsub(/"/, "\\\"")
          .gsub(/\n/, "\\n")
          .gsub(/\r/, "\\r")
          .gsub(/</, "\\u003C")
      end
      
      # Highlight text with search term while maintaining HTML safety
      # @param text [String] The text to search within
      # @param term [String] The search term to highlight
      # @param highlight_tag [String] HTML tag to use for highlighting (default: 'mark')
      # @param css_class [String] CSS class to add to highlight tag (optional)
      # @return [String] Text with highlighted terms
      def highlight_text(text, term, highlight_tag: 'mark', css_class: nil)
        return text if term.empty? || text.empty?
        
        # First purify the text to make it safe
        safe_text = purify_html(text)
        safe_term = purify_html(term)
        
        # Escape the term for regex
        escaped_term = Regexp.escape(safe_term)
        
        # Build the opening tag with optional CSS class
        opening_tag = if css_class
          "<#{highlight_tag} class=\"#{purify_html_attribute(css_class)}\">"
        else
          "<#{highlight_tag}>"
        end
        
        closing_tag = "</#{highlight_tag}>"
        
        # Highlight the term
        safe_text.gsub(/(#{escaped_term})/i) do |match|
          "#{opening_tag}#{match}#{closing_tag}"
        end
      end
      
      # Alternative highlighting with span and default Bootstrap classes
      # @param text [String] The text to search within
      # @param term [String] The search term to highlight
      # @param highlight_class [String] CSS class for highlighting (default: 'bg-warning text-dark px-1 rounded')
      # @return [String] Text with highlighted terms
      def highlight_with_class(text, term, highlight_class: 'bg-warning text-dark px-1 rounded')
        highlight_text(text, term, highlight_tag: 'span', css_class: highlight_class)
      end
      
      # ========== HTML HELPER METHODS ==========
      
      # Truncate text to specified length
      # @param text [String] The text to truncate
      # @param length [Integer] Maximum length before truncation (default: 100)
      # @param suffix [String] Suffix to add when truncated (default: '...')
      # @param preserve_words [Boolean] Whether to preserve whole words (default: false)
      # @return [String] Truncated text
      def truncate_text(text, length: 100, suffix: '...', preserve_words: false)
        return '' unless text
        text = text.to_s
        
        if text.length <= length
          return text
        end
        
        if preserve_words
          # Try to break at a word boundary
          truncated = text[0, length]
          last_space = truncated.rindex(/\s/)
          
          if last_space && last_space > length * 0.8  # Only break if we have a reasonable word boundary
            truncated = text[0, last_space]
          end
          
          truncated + suffix
        else
          text[0, length] + suffix
        end
      end
      
      # Create a safe HTML link
      # @param text [String] The link text
      # @param url [String] The link URL
      # @param attrs [Hash] Additional HTML attributes (e.g., {class: 'btn', target: '_blank'})
      # @return [String] Safe HTML <a> tag
      def link_to(text, url, **attrs)
        # Build attributes string
        attr_string = attrs.map do |key, value|
          "#{key}=\"#{purify_html_attribute(value)}\""
        end.join(' ')
        
        attr_string = " #{attr_string}" unless attr_string.empty?
        
        "<a href=\"#{purify_html_attribute(url)}\"#{attr_string}>#{purify_html(text)}</a>"
      end
      
      # Format datetime object
      # @param datetime [Time, DateTime, String] The datetime to format
      # @param format [String] strftime format string (default: '%Y-%m-%d %H:%M')
      # @param default [String] Default value if datetime is nil (default: '')
      # @return [String] Formatted datetime
      def format_datetime(datetime, format: '%Y-%m-%d %H:%M', default: '')
        return default unless datetime
        
        if datetime.is_a?(String)
          # Try to parse the string
          begin
            datetime = Time.parse(datetime)
          rescue
            return default
          end
        end
        
        if datetime.respond_to?(:strftime)
          datetime.strftime(format)
        else
          default
        end
      end
      
      # Format a number with commas (e.g., 1000 -> "1,000")
      # @param number [Numeric, String] The number to format
      # @param delimiter [String] Thousands delimiter (default: ',')
      # @param separator [String] Decimal separator (default: '.')
      # @return [String] Formatted number
      def number_with_delimiter(number, delimiter: ',', separator: '.')
        return '' unless number
        
        parts = number.to_s.split('.')
        parts[0] = parts[0].reverse.scan(/\d{1,3}/).join(delimiter).reverse
        
        parts.join(separator)
      end
      
      # Pluralize a word based on count
      # @param count [Integer] The count
      # @param singular [String] Singular form of the word
      # @param plural [String] Plural form of the word (optional, will add 's' by default)
      # @return [String] Pluralized phrase
      def pluralize(count, singular, plural = nil)
        plural ||= singular + 's'
        count == 1 ? "1 #{singular}" : "#{count} #{plural}"
      end
    end
  end
end