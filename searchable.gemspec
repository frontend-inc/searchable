# frozen_string_literal: true

require_relative "lib/searchable/version"

Gem::Specification.new do |spec|
  spec.name = "searchable"
  spec.version = Searchable::VERSION
  spec.authors = ["Rami Bitar"]
  spec.email = ["rbitar@gmail.com"]

  spec.summary = "ActiveRecord query parsing and filtering from URL parameters"
  spec.description = "A Ruby gem that provides a clean DSL for parsing URL query parameters and applying filters, sorting, and pagination to ActiveRecord models."
  spec.homepage = "https://github.com/your-repo/searchable"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir.glob("{lib}/**/*") + %w[Gemfile Rakefile searchable.gemspec]

  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "kaminari", ">= 1.0"
end
