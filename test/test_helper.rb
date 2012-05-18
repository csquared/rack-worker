require 'bundler'
Bundler.require :default, :test
require 'webmock/test_unit'
require "#{File.dirname(__FILE__)}/../lib/rack-worker"

def QC.enqueue(function_call, *args)
  eval("#{function_call} *args")
end

class Rack::Worker::TestCase < Test::Unit::TestCase
  include Rack::Test::Methods
  include RR::Adapters::TestUnit

  def setup
    super
    @old_cache = Rack::Worker.cache
  end

  def teardown
    super
    WebMock.reset!
    Rack::Worker.cache = @old_cache if @old_cache
  end

  def default_test
    #fu test::unit
  end
end

class ContainedSinatraApp < Sinatra::Base
  use Rack::Worker

  get '*' do
    headers 'Content-Type' => 'text/test'
    'Hello, world'
  end
end

class TestSinatraApp < Sinatra::Base
  get '*' do
    headers 'Content-Type' => 'text/test'
    'Hello, world'
  end
end

class RackApp
  def call(env)
    [200, {"Content-Type" => "text/test"}, ['Hello, world']]
  end
end
