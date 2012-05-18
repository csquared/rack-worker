require 'test_helper'

module QueueTest
  def test_processes_request_in_queue
    Rack::Worker.cache = Object.new
    mock(Rack::Worker.cache).get('response-/foo?') { false }
    mock(Rack::Worker.cache).get('env-/foo?') { false }
    mock(Rack::Worker.cache).get('env-/foo?') { {'rack.input' => []}.to_json }
    mock(Rack::Worker.cache).add('env-/foo?', is_a(String))
    mock(Rack::Worker.cache).add('response-/foo?', is_a(String))

    mock_queue = Object.new
    def mock_queue.enqueue(function_call, *args)
      eval("#{function_call} *args")
    end
    Rack::Worker.queue = mock_queue

    get '/foo'
    assert_equal 202, last_response.status
  end
end

class WorkerTest < Rack::Worker::TestCase
  include QueueTest

  def app
    Rack::Builder.new do
      use Rack::Worker
      run RackApp
    end
  end

  def test_returns_empty_202_and_queues_when_not_in_cache_or_queue
    Rack::Worker.cache = Object.new
    mock(Rack::Worker.cache).get('response-/foo?') { false }
    mock(Rack::Worker.cache).get('env-/foo?')      { false }
    stub(Rack::Worker.cache).add

    Rack::Worker.queue = Object.new
    mock(Rack::Worker.queue).enqueue('Rack::Worker.process_request', is_a(String), '/foo?')

    get '/foo'
    assert_equal 202, last_response.status
    assert_equal '', last_response.body
  end

  def test_returns_empty_202_and_does_not_queue_when_not_in_cache_and_in_queue
    Rack::Worker.cache = Object.new
    mock(Rack::Worker.cache).get('response-/foo?') { false }
    mock(Rack::Worker.cache).get('env-/foo?')      { true }

    get '/foo'
    assert_equal 202, last_response.status
    assert_equal '', last_response.body
  end

  def test_returns_response_in_queue
    json = "{\"Hello\":\"World\"}"
    Rack::Worker.cache = Object.new
    mock(Rack::Worker.cache).get('response-/foo?') do
      [302, {"Content-Type" => "application/json"}, [json]].to_json
    end

    get '/foo'
    assert_equal 302, last_response.status
    assert_equal 'application/json', last_response.headers['Content-Type']
    assert_equal json, last_response.body
  end
end

class SinatraTest < Rack::Worker::TestCase
  include QueueTest

  def app
    Rack::Builder.new do
      use Rack::Worker
      run TestSinatraApp
    end
  end
end

class SinatraUseTest < Rack::Worker::TestCase
  include QueueTest

  def app
    ContainedSinatraApp
  end
end

class RackClassTest < Rack::Worker::TestCase
  include QueueTest

  def app
    Rack::Builder.new do
      use Rack::Worker
      run RackClassApp
    end
  end
end
