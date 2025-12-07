# frozen_string_literal: true

require_relative "lib/hyraft/version"

Gem::Specification.new do |spec|
  spec.name = "hyraft"
  spec.version = Hyraft::VERSION
  spec.licenses    = ['MIT']
  spec.summary = "Ruby framework built for change with adapter architecture."
  spec.description = "Hyraft is a full-stack Ruby web framework that combines high-performance hexagonal architecture with modern reactive frontend capabilities. Build scalable applications with clean separation of concerns."
  spec.authors = ["Demjhon Silver"]
  spec.files = Dir[
    "lib/**/*.rb",
    "templates/**/*",
    "exe/*",
    "*.md", 
    "LICENSE.txt"
  ]
  spec.homepage    = 'https://rubygems.org/gems/hyraft'
  spec.metadata = {
    "homepage_uri"      => "https://hyraft.com",
    "source_code_uri"   => "https://github.com/demjhonsilver/hyraft",
  }

  spec.required_ruby_version = ">= 3.4.0"
  spec.bindir = "exe"
  spec.executables = ["hyraft"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", "~> 3.2"
  spec.add_dependency "dotenv", "~> 3.1", ">= 3.1.8"
  spec.add_dependency "hyraft-server", "~> 0.1.0"
  spec.add_dependency "hyraft-rule", "~> 0.1.0.alpha1"
  spec.add_dependency "sequel", "~> 5.98"



  # Runtime dependencies
  spec.add_development_dependency "rake", "~> 13.3"
  spec.add_development_dependency "minitest", "~> 5.26"
  spec.add_development_dependency "minitest-reporters", "~> 1.7", ">= 1.7.1"
  spec.add_development_dependency "minitest-focus", "~> 1.4"
  spec.add_development_dependency "mocha", "~> 2.8"
  spec.add_development_dependency "rack-test", "~> 2.2"


end