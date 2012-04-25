require 'test_helper'

class PostgresCacheTest < Rack::Worker::TestCase

  def setup
    skip("Need to define TEST_DATABASE_URL") unless ENV['TEST_DATABASE_URL']
    @cache = Rack::Worker::PostgresCache.new(ENV['TEST_DATABASE_URL'], :cache)
  end

  def teardown
    skip("Need to define TEST_DATABASE_URL") unless ENV['TEST_DATABASE_URL']
    @cache.db << "DROP TABLE cache;"
  end

  def test_adds_records
    @cache.add('foo', 'bar')
    assert_equal 'bar', @cache.get('foo')
  end

  def test_delete
    @cache.add('foo', 'bar')
    assert_equal 'bar', @cache.get('foo')
    @cache.delete('foo')
    assert_equal nil, @cache.get('foo')
  end
end
