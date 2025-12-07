# lib/hyraft.rb
# frozen_string_literal: true

require 'fileutils'
require_relative "hyraft/system_info"
require_relative "hyraft/cli" 
require_relative "hyraft/version"

require_relative "hyraft/engine/source"
require_relative "hyraft/engine/circuit"
require_relative "hyraft/engine/port"
require_relative "hyraft/engine"

# compiler components
require_relative "hyraft/compiler/compiler"
require_relative "hyraft/compiler/parser"
require_relative "hyraft/compiler/renderer"
require_relative "hyraft/compiler/javascript_library"  

# router components
require_relative "hyraft/router/api_router"
require_relative "hyraft/router/web_router"

# PRELOADER
require_relative "hyraft/boot/preloader"
require_relative "hyraft/boot/asset_preloader"
require_relative "hyraft/boot/preloaded_static"

require_relative "hyraft/compiler/javascript_obfuscator"

module Hyraft
  class Error < StandardError; end
end

# Define the standard top-level constants
HyraftCompiler = Hyraft::Compiler::HyraftCompiler
HyraftParser = Hyraft::Compiler::HyraftParser
HyraftRenderer = Hyraft::Compiler::HyraftRenderer

# Top-level aliases for backward compatibility
ApiRouter = Hyraft::Router::ApiRouter
WebRouter = Hyraft::Router::WebRouter

# ADD PRELOADER ALIAS
HyraftPreloader = Hyraft::Preloader
HyraftAssetPreloader = Hyraft::AssetPreloader
HyraftPreloadedStatic = Hyraft::PreloadedStatic

