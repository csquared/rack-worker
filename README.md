# Rack::Worker

[![Build Status](https://secure.travis-ci.org/[YOUR_GITHUB_USERNAME]/[YOUR_PROJECT_NAME].png)](http://travis-ci.org/[csquared]/[rack-worker])

  Rack middleware that implements the Worker Pattern.

  It processes GET requests with a worker backend and only serves them straight from a cache.  
  While processing the request it serves empty HTTP 202 responses.
  Your web frontend is never blocked processing the request.


## How it works

  When GET requests hit your app, the middleware tries to serve them from the cache.

  If the request is not found, it stores the environment data in the cache.  A worker
  process will then use the `App.call(env)` convention from Rack to run the request through
  your webapp in the background as if it were a normal Rack request.  The status, headers,
  and body are then stored in the cache so they can be served.  

  What makes this technique different from a standard HTTP caching approach is that your
  web server never processes the long HTTP request.  The middleware will return empty 
  HTTP 202 responses unless the response is found in the cache.  Every request that generates
  a 202 will only queue one background job per URL.

## Installation

Add this line to your application's Gemfile:

    gem 'rack-worker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-worker

## Usage

```ruby
class  App < Sinatra::Base
  use Rack::Worker

  get '/long_ass_request' do
    long_ass_work
  end
end
```

That's it! Now GETs to `/long_ass_request` will be processed in the background and only
serve HTTP 202 responses until they are processed, after which they will return whatever your
app would have returned.

If you already have `queue_classic` and `dalli` installed, everything will *just work*.

See configuration for setting an expiry time on records.

## Configuration

```ruby
  Rack::Worker.cache = Dalli::Client.new(nil, {:expires_in => 300})
```
The `cache` can be anything that responds to `get(key)` and `set(key, string)`

```ruby
  Rack::Worker.queue = QC
```
The `queue` can be anything that responds to `enqueue(method, *params)` 


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
