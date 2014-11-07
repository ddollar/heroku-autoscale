require "rubygems"
require "rack/test"
require "rspec"

$:.unshift "lib"

RSpec.configure do |config|
  config.color_enabled = true
  config.mock_with :rspec
end

# Mock Rails.cache
module Rails
  def self.cache; end
end