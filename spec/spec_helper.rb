require "rubygems"
require "rack/test"
require "rspec"

$:.unshift "lib"

Rspec.configure do |config|
  config.color_enabled = true
  config.mock_with :rr
end
