# framework/compiler/style_resolver.rb

require 'pathname'

module Compiler
  module StyleResolver
    module_function

    def resolve_style_path(path, from:)
      # normalize path (remove leading slash if present)
      rel_path = path.start_with?('/') ? path.sub(%r{^/}, '') : path

      # 1) public/ takes priority: public/styles/css/example.css -> /styles/css/example.css
      public_path = File.join(ROOT, 'public', rel_path)
      return "/#{rel_path}" if File.exist?(public_path)

      # 2) FIXED: Update to new structure path
      local_path = File.expand_path(File.join(File.dirname(from), rel_path))

      #  CORRECT: New structure path
      display_root = File.expand_path(File.join(ROOT,'adapter-intake'))

      if local_path.start_with?(display_root) && File.exist?(local_path)
          # compute path relative to adapter-intake and return a browser URL
        relative = Pathname.new(local_path).relative_path_from(Pathname.new(display_root)).to_s
        return "/#{relative}"
      end

      # not found
      raise "Stylesheet not found: #{path} (searched #{public_path} and #{local_path})"
    end
  end
end