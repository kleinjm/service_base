# BaseService

A base service class for Ruby applications that provides common functionality and argument type annotations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "base_service"
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install base_service
```

## Usage

```ruby
require "base_service"

class MyService < BaseService::BaseService
  def call
    # Your service logic here
  end
end

# Call the service
MyService.call
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the MIT License.