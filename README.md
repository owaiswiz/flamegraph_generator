# FlamegraphGenerator

A super simple gem that allows you to create flamegraphs that can be opened via [speedscope.app](https://speedscope.app/).

This differs from tools like stackprof/singed/rack-mini-profiler in that this allow *you* to specify the events used to create a flamegraph.
Whereas those tools automatically create flamegraph based on the call stack.

You might want to use this gem if you've got a need to create flamegraphs from a custom event source.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add flamegraph_generator

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install flamegraph_generator

## Usage

```ruby
# Initialize generator
#
# Parameters
#  - name: String
#     Optional. Defaults to 'flamegraph'
#  - units: 'none' | 'nanoseconds' | 'microseconds' | 'milliseconds' | 'seconds' | 'bytes'
#     Optional. Defaults to 'seconds'
generator = FlamegraphGenerator.new(name: 'myflamegraph', units: 'seconds')

# Add your events here
generator.add_event(name: 'UsersComponent', start: 0, finish: 100)
generator.add_event(name: 'X', start: 50, finish: 70, file: 'xxx.rb', line: 200, col: 10)
generator.add_event(name: 'Y', start: 112, finish: 130, file: 'yyy.rb', line: 200, col: 10)

# Will save the flamegraph to /tmp/flamegraph.json + open the flamegraph in your browser
generator.save(path: '/tmp/flamegraph.json', open: true)

# You can also get the raw speedscope-compatible flamegraph hash by:
generator.generate_flamegraph
```

## Contrived example

The below example hooks into the notifications dispatched by the [view_component](https://viewcomponent.org/guide/instrumentation.html) library and generates a flamegraph during each request for view components.
```ruby
class ApplicationController
    around_action :vc_bm

    def vc_bm
        return yield unless Rails.env.development?

        generator = FlamegraphGenerator.new
        callback = lambda do |name, start, finish, id, payload|
            generator.add_event(name: payload[:name], start:, finish:)
        end

        ActiveSupport::Notifications.subscribed(callback, 'render.view_component', monotonic: true) do
            yield
        end

        generator.save(path: Rails.root.join('tmp', 'vc_bm.json'), open: true)
    end
end
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/owaiswiz/flamegraph_generator.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
