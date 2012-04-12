# Rack::Worker

  Rack middleware that implements the Worker Pattern
  Processes GET requests with a worker backend and only serves them straight from a cache.  
  Your web frontend is never blocked processing the request.

## Installation

Add this line to your application's Gemfile:

    gem 'rack-worker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-worker

## Configuration

```ruby
  Rack::Worker.cache = Dalli::Client.new(nil, {:expires_in => 300})
```
The `cache` can be anything that responds to `get(key)` and `set(key, string)`

```ruby
  Rack::Worker.queue = QC
```
The `queue` can be anything that responds to `enqueue(method, *params)` 


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
serve HTTP 202 responses until it is processed, after which it will serve whatever your
app would have returned.

If you already have `queue_classic` and `dalli` installed, everything will *just work*.
However, see the example above for setting an expiry time on records.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
