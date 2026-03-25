# frozen_string_literal: true

require_relative "lib/linkedin/voyager_api/version"

Gem::Specification.new do |spec|
  spec.name = "linkedin-voyager_api"
  spec.version = LinkedIn::VoyagerApi::VERSION
  spec.authors = ["Marcin Ostrowski"]
  spec.summary = "Ruby client for LinkedIn's Voyager API"
  spec.description = "Cookie-based Ruby client for LinkedIn's internal Voyager API. " \
                     "Provides access to feeds, profiles, and company data."
  spec.homepage = "https://github.com/fryga/linkedin-voyager_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "logger"
end
