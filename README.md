# Service Base

A base service class for Ruby applications that provides common functionality and argument type annotations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "service_base"
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install service_base
```

To follow convention in a Rails application, it's recommended that you create an `ApplicationService` subclass.

```rb
class ApplicationService < ServiceBase::Service
end
```

# Base Service Pattern

The general concept of a Service Pattern is useful when a you need to execute a set of
sequential steps. The service encapsulates those steps into a single class with a single action to trigger the steps.

The Base Service Pattern uses a modified [Railway
Pattern](https://fsharpforfunandprofit.com/posts/recipe-part2/) set up and enforced by the `Service` class,
which every service inherits from.

## Recommended resources

- Highly recommended video inspiring this pattern: [Service Objects with
Dry.rb](https://www.youtube.com/watch?v=YXiqzHMmv_o)
- [Essential
RubyOnRails patterns — part 1: Service Objects](https://medium.com/selleo/essential-rubyonrails-patterns-part-1-service-objects-1af9f9573ca1)
- [Ruby
on Rails pattern: Service Objects](https://dev.to/joker666/ruby-on-rails-pattern-service-objects-b19)

## Advantages

- The action of a service should read as a list of steps which makes
reading and maintaining the service easy.
- Instantiation of a service object allows fine grained control over
the arguments being passed in and reduces the need to pass arguments
between methods in the same instance.
- Encapsulation of logic in a service makes for reusable code, simpler
testing, and extracts logic from other objects that should not be
responsible for handling that logic.
- Verb-naming makes the intention of the service explicit.
- Single service actions reveal a single public interface.

## What defines a service?

- The main difference between a model and a service is that a model
“models” **what** something is while a service lists
**how** an action is performed.
- A service has a single public method, ie. `call`
- A model is a noun, a service is a verb’ed noun that does the one
thing the name implies
    - Ie. `User` (model) versus `User::CreatorService` (service)
    - Ie. `StripeResponse` (model) versus `PaymentHistoryFetcherService` (service)

## Naming

One of the best ways to use the service pattern is for CRUD services - Ie. `ActiveRecordModel` +
`::CreateService`, `::UpdateService`,
`::DeleteService`. This avoids the use of callbacks, mystery guests, and unexpected side effects because all the steps to do a CRUD action are in one place and in order.

## Returning a Result

Each service inheriting from BaseService must define
`#call` and return a `Success` or
`Failure`. These types are `Result` Monads from
the dry-monads gem. Both `Result` types may take any value as
input, ie. `Success(user)`,
`Failure(:not_found)`

`Failure` can return any value you’d like the caller to have in order to understand the failure.

The caller of service can unwrap the Success, Failure or like so

```ruby
MyService.call(name: user.name) do |on|
	on.success { |value| some_method(value) }
	on.failure { |error| log_error(error) }
end
```

To match different expected values of success or failure, pass the
value as an argument.

```ruby
MyService.call(name: user.name) do |on|
  on.success(:created) { notify_created! }
  on.failure(ActiveRecord::NotFound) { log_not_found }
  on.failure(:invalid) { render(code: 422) }
  on.failure { |error| raise(RuntimeError, error) }
end
```

Note that you must define both `on.success` and
`on.failure` or else an error will be raised in the
caller.

Note that `raise`ing an error requires an error class
unless the error itself is an instance of an error class.

Please see [result](https://dry-rb.org/gems/dry-monads/1.3/result/) for
additional mechanisms used for chaining results and handling
success/failure values.

A recommended pattern within services is to return a
`Success` and/or `Failure` from each method and
yield the result in the caller. This forces you to consider how each
method could fail and allows for automatic bubbling up of the
`Failure` via railway-style programming. Examples at [https://dry-rb.org/gems/dry-monads/1.3/do-notation/#adding-batteries](https://dry-rb.org/gems/dry-monads/1.3/do-notation/#adding-batteries)

## Failures vs Exceptions

Failure = a known error case that may happen and should be gracefully
handled

Raising = an unexpected exception (exceptional circumstances)

Any call that `raise`s is not rescued by default and will
behave as a typical Ruby exception. This is a good thing. We will be
alerted when exceptional circumstances arise.

Return a `Failure` instead when you know of a potential
failure case.

Avoid rescuing major error/exception superclasses such as
`StandardError`. Doing so will rescue all subclasses of that
error class. If you need to raise an error for control flow, favor a
specific error or custom error class.

```ruby
# bad
rescue StandardError => e
  Failure(e)
end

# good - known failure case
return Failure("Number #{num} must be positive") if arg.negative?

# good - exception required for control flow
rescue ActiveRecord::Rollback
  Failure("Record invalid: #{record.inspect}")
end
```

## Arguments

Arguments to a service are defined via the `argument` DSL.
The positional name and type arguments are required, the other options
are as follows.
`argument(:name, String, optional: true, description: "The User's name")`

If an argument is optional and has a default value, simply set `default: your_value` but do not also specify `optional: true`.
Doing so will raise an `ArgumentError`.
Additionally, be sure to `.freeze` any mutable default values, ie.  `default: {}.freeze`.
Failure to do so will raise an `ArgumentError`.

To allow multiple types as arguments, use `|`. For example,

```rb
argument(:value, String | Integer)
```

Empty strings attempted to coerce into integers will throw an error.
See [https://github.com/dry-rb/dry-types/issues/344#issuecomment-518743661](https://github.com/dry-rb/dry-types/issues/344#issuecomment-518743661)
To instead accept `nil`, do the following:
`argument(:some_integer, Params::Nil | Params::Integer)`

A service should also define a `description`. This is
recommended for self-documentation, ie.

```ruby
class MyService < ServiceBase::Service
  description("Does a lot of cool things")
end
```

To get the full hash of `argument`'s keys and values passed into a service,
use `arguments`. This is a very useful technique for
services that update an object. For example

```ruby
class User::UpdateService < ServiceBase::Service
  argument(:name, String)

  def call
    user.update(arguments)
  end
end
```

## Types

Argument types come from, [Dry.rb’s Types](https://dry-rb.org/gems/dry-types/1.2/built-in-types/), which can be extended.
You may also add custom types as outlined in [Dry.rb Custom Types](https://dry-rb.org/gems/dry-types/1.2/custom-types/).

It is recommended that you define your own `Type` module and include it in your `ServiceBase` subclass, as so.

```rb
# app/models/types.rb
module Types
  ApplicationRecord = Types.Instance(ApplicationRecord)
  ControllerParams = ServiceBase::Types.Instance(ActionController::Parameters)
end

# app/services/application_service.rb
class ApplicationService < ServiceBase::Service
  include Types
end

# app/services/example_service.rb
class ExampleService < ApplicationService
  argument(:user, ApplicationRecord, description: "The user to update")
  argument(:params, ControllerParams, description: "The attributes to update")
end
```

You can also limit the type of `ApplicationRecord` record via

`argument(:user, Types.Instance(User))`

Or defining `User = Types.Instance(User)`

Note: In order to access constants outside of the dry.rb namespace,
or to access a type that collides with one of our defined types, you
must include `::` to allow a global constant search.

Ie. `::ApplicationRecord...`

`Coercible` and `Params` Types are very
powerful and recommended for automatic parsing of inputs, ie. controller
parameters.

For example `argument(:number, Params::Integer)` will convert `"12"` ⇒ `12`.

Entire hash structures may also be validated and automatically parsed, for example:

```ruby
argument(
  :line_items,
  Array(
    Hash.schema(
      vintage_year: Params::Integer,
      number_of_credits: Params::Integer,
      price_dollars_usd: Params::Float,
    ),
  ),
```

## Working with transactions

⚠️  If your service makes more than one write call to the DB, you
should wrap all operations in a single transaction with
`::ApplicationRecord.transaction`.

According to the [Dry
RB docs](https://dry-rb.org/gems/dry-monads/1.3/do-notation/#transaction-safety):

> Under the hood, Do uses exceptions to halt unsuccessful
operations…Since yield internally uses exceptions to
control the flow, the exception will be detected by
the transaction call and the whole operation will be rolled
back.
>

Therefore, `yield`ing a `Failure` will roll
back the transaction without having to add any explicit exception
handling via `rescue`.

In Rails 7, using `return` inside a transaction [will
roll the transaction back](https://www.loyalty.dev/posts/returning-from-transactions-in-rails). Therefore,
`return Failure(...)` within a transaction will roll back, as well as `yield`ing a `Failure` within a transaction.

## Internal Method Result

The Railway Pattern can be used internally within services via
`yield` and `do` notation. This forces the
programmer to think about the success and failure cases within each
method. See [the dry-monads gem](https://dry-rb.org/gems/dry-monads/1.3/) for more details.

If the internal methods of the service need to unwrap values, those specific methods need to be registered with the result matcher like so.

```ruby
include Dry::Matcher.for(:method_name, with: Dry::Matcher::ResultMatcher)
```

Within the service, the registered method can then be pattern matched and unwrapped.

```ruby
method_name(order:) do |on|
  on.success(:deleted) { true }
  on.success(:cancelled) { destroy_order(order:) }
  on.failure { |error| raise(RuntimeError, error) }
end
```

## Gotchas

- `yield`ing does not work inside `concerning`
blocks or other sub-modules. See [https://github.com/dry-rb/dry-monads/issues/68#issuecomment-1042372398](https://github.com/dry-rb/dry-monads/issues/68#issuecomment-1042372398)

## Misc

- To get a pretty printed description of a service and it’s args, run `ServiceClass.pp`

## Test Support

The following methods are made available by including the base service testing in your test suite.

```ruby
require "service_base/rspec"
```

```ruby
stub_service_success(User::CreateService)
stub_service_success(User::CreateService, success: true)
stub_service_success(User::CreateService, success: create(:user))

stub_service_failure(User::CreateService, failure: "error")
stub_service_failure(User::CreateService failure: :invalid_email, matched: true)
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the MIT License.