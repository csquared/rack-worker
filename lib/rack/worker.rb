require 'rack/worker/version'

module Rack
  class Worker
    def initialize(app)
      @app = app
    end

    def cache
      self.class.cache
    end

    def self.cache
      @cache ||= defined?(::Dalli) ? ::Dalli::Client.new : nil
    end

    def call(env)
      # so when worker calls app we don't return 204
      return @app.call(env) if env['rack.worker_qc']

      if env['REQUEST_METHOD'] == 'GET'
        key = key(env)
        if response = get_response(key)
          response
        else
          unless cache.get("env-#{key}")
            cache.set("env-#{key}", env.to_json)
            QC.enqueue("#{self.class.name}.process_request", 
                       @app.class.name, key)
          end
          [202, {"Content-type" => "text/plain"}, []]
        end
      end
    end

    def self.process_request(classname, id)
      env = Yajl::Parser.parse(cache.get("env-#{id}"))
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
      Yajl::Parser.parse(response)
    end

    def key(env)
      env['REQUEST_PATH'] + '?' + env['QUERY_STRING']
    end
  end
end
