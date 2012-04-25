require 'test_helper'

class ExpireTest < Rack::Worker::TestCase

  def app
    ContainedSinatraApp
  end

  def teardown 
    Rack::Worker.db[Rack::Worker.cache_table_name].where("key like '%foo%'").delete 
  end

  def visit(url)
    get url
    assert_equal 202, last_response.status
    get url
    assert_equal 200, last_response.status
  end

  def assert_expires_url(url)
    visit url
    yield
    get url
    assert_equal 202, last_response.status
  end

  def assert_doesnt_expire_url(url)
    visit url
    yield
    get url
    assert_equal 200, last_response.status
  end

  def test_expire_with_url
    assert_expires_url '/foo' do
      Rack::Worker.expire('/foo')
    end
  end

  def test_expire_with_no_get_params_expires_all_with_url
    assert_expires_url '/foo?query=param' do
      Rack::Worker.expire('/foo')
    end
  end

  def test_expires_with_one_get_param
    assert_expires_url '/foo?query=param' do
      Rack::Worker.expire('/foo', :query => 'param')
    end
  end

  def test_expire_with_1_matching_param
    assert_expires_url '/foo?query=param&query2=param2&query3=param3' do 
      Rack::Worker.expire('/foo', :query => 'param')
    end
  end

  def test_expires_with_some_matching_params
    assert_expires_url '/foo?query=param&query2=param2&query3=param3' do 
      Rack::Worker.expire('/foo', :query => 'param', :query2 => 'param2')
    end
  end

  def test_expires_with_all_matching_params
    assert_expires_url '/foo?query=param&query2=param2&query3=param3' do 
      Rack::Worker.expire('/foo', :query => 'param', :query2 => 'param2', :query3 => 'param3')
    end
  end

  def requires_params_to_match
    assert_doesnt_expire_url '/foo?query=param&query2=param2&query3=param3' do 
      Rack::Worker.expire('/foo', :query => 'param2')
    end
  end
end

class ExpireRaiseTest < Rack::Worker::TestCase
  def test_raises_if_wrong_cache
    @raise_test = true
    Rack::Worker.cache = Object.new
    assert_raises RuntimeError, 'Worker::expire only works with PostgresCache' do
      Rack::Worker.expire('/foo')
    end
  end
end
