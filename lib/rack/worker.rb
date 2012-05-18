require 'rack/worker/version'
require 'rack/worker/postgres_cache'
require 'json'

module Rack
  class Worker
    def initialize(app)
      @app = app
    end

    def cache
      self.class.cache
    end

    def queue
      self.class.queue
    end

    def db
      self.class.db
    end

    def self.cache
      return @cache if defined? @cache
      @cache = PostgresCache.new(db_url, cache_table_name, nil) if db_url
    end

    def self.queue
      (defined?(@queue) && @queue) || (defined?(QC) && QC)
    end

    def self.db
      return @db if defined? @db
      @db = ::Sequel.connect(db_url)
    end

    def self.db_url
      @db_url || ENV['RACK_WORKER_DATABASE_URL'] || ENV['DATABASE_URL']
    end

    class << self
      attr_writer :queue
      attr_writer :cache
      attr_writer :db
      attr_writer :db_url
    end

    def self.cache_table_name
      ENV['RACK_WORKER_CACHE_TABLE'] || :rack_worker_cache
    end

    # Given a string that starts with a slash,
    #   anchor it to the beginning of the string
    #   allow * within url
    # Given a hash as the second argument,
    #   filter urls with those GET params
    def self.expire(url, get_params = {})
      raise "Expire only works with PosgresCache" unless cache.is_a? PostgresCache
      self.find(url, get_params).update(:expires_on => Time.now)
    end

    def self.find(url, get_params)
      data = cache.db[cache_table_name].filter(:key => /\A(response|env)-#{Regexp.escape(url)}\?/)
      (get_params || []).each do |key, value|
        data = data.filter("key like '%#{key}=#{value}%'")
      end
      data
    end

    def call(env)
      # so when worker calls app we don't return 204
      # or if there is no cache just pass the request through
      return @app.call(env) if env['rack.worker_qc'] || !cache

      if env['REQUEST_METHOD'] == 'GET'
        key = key(env)
        if response = get_response(key)
          response
        else
          unless cache.get("env-#{key}")
            cache.add("env-#{key}", env.to_json)
            name = @app.is_a?(Class) ? @app.name : @app.class.name
            queue.enqueue("#{self.class.name}.process_request", name, key)
          end
          [202, {"Content-type" => "text/plain"}, []]
        end
      end
    end

    def self.process_request(classname, id)
      env = cache.get("env-#{id}")
      return unless env
      env = JSON.parse(env).merge('rack.worker_qc' => true)
      app = classname_to_class(classname)
      if app.respond_to? :call
        status, headers, body = app.call(env)
      else
        status, headers, body = app.new.call(env)
      end
      set_response(id, status, headers, body)
    end

    def self.classname_to_class(classname)
      classname.split("::").inject(Object){ |klass, classname| klass.const_get classname }
    end

    def self.set_response(key, status, headers, body)
      cache.add("response-#{key}", [status, headers, body].to_json)
    end

    def get_response(key)
      response = cache.get("response-#{key}")
      return unless response
      JSON.parse(response)
    end

    def key(env)
      (env['REQUEST_PATH'] || env['PATH_INFO']) + '?' + env['QUERY_STRING']
    end
  end
end
