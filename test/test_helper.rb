require 'bundler'
Bundler.require :test
require 'webmock/test_unit'
require "#{File.dirname(__FILE__)}/../lib/rack-worker"

class Rack::Worker::TestCase < Test::Unit::TestCase
  include Rack::Test::Methods
  include RR::Adapters::TestUnit

  def teardown
    super
    WebMock.reset!
  end
end
