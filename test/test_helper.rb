# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "linkedin/voyager_api"
require "minitest/autorun"
require "json"

module FixtureHelper
  def fixture_path(name)
    File.join(File.dirname(__FILE__), "fixtures", name)
  end

  def load_fixture(name)
    JSON.parse(File.read(fixture_path(name)))
  end
end
