# infra/server/web-server.ru
require_relative './../../boot'
require 'hyraft/server'

public_path = File.expand_path("../../public", __dir__)
root_path = File.expand_path("../..", __dir__) 

# Preload everything 

# HyraftPreloader.preload_templates

# HyraftAssetPreloader.preload_assets(public_path)

# Serve node_modules FIRST
use Rack::Static, {
  urls: ["/node_modules"],
  root: root_path,
  index: 'index.html'
}

# Then serve public assets
use Rack::Static, {
   urls: ["/styles", "/css", "/images", "/js", "/icons", "/favicon.ico"], # You can add files like robot.txt
  root: public_path,
  index: 'index.html'
}

use WebLogger
use Rack::MethodOverride

run ServerWebAdapter.new

