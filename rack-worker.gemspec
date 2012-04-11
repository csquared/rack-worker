# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack/worker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Chris Continanza"]
  gem.email         = ["christopher.continanza@gmail.com"]
  gem.description   = %q{Rack middleware that implements the Worker Pattern}
  gem.summary       = %q{Processes GET requests with a worker backend and only serves them straight from a cache.  Your web frontend is never blocked processing the request. Implementation of the Worker Pattern}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "rack-worker"
  gem.require_paths = ["lib"]
  gem.version       = Rack::Worker::VERSION
end
