require 'rack/worker/version'
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

    def self.cache
      return @cache if defined? @cache
      @cache = ::Dalli::Client.new if defined?(::Dalli)
    end

    def self.queue
      (defined?(@queue) && @queue) || (defined?(QC) && QC)
    end

    class << self
      attr_writer :queue
      attr_writer :cache
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
            cache.set("env-#{key}", env.to_json)
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
      env = JSON.parse(env)
      app = classname_to_class(classname) 
      status, headers, body = app.call(env.merge('rack.worker_qc' => true))
      set_response(id, status, headers, body)
    end

    def self.classname_to_class(classname)
      classname.split("::").inject(Object){ |klass, classname| klass.const_get classname }
    end

    def self.set_response(key, status, headers, body)
      cache.set("response-#{key}", [status, headers, body].to_json)
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
