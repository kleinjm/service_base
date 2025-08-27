# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Ruby gem called `service_base` that provides a base service class for Ruby applications with argument type annotations and railway-oriented programming using dry-rb gems. It implements the Service Object pattern with built-in type validation and monadic error handling.

## Development Commands

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec
# or
rake spec

# Run a specific test file
bundle exec rspec spec/service_base/service_spec.rb

# Build gem
bundle exec rake build

# Install gem locally for testing
bundle exec rake install
```

## Architecture

### Core Components

- **ServiceBase::Service** (`lib/service_base/service.rb`): The main base class that all services inherit from. Uses dry-struct for argument validation and dry-monads for Result handling.
- **ArgumentTypeAnnotations** (`lib/service_base/argument_type_annotations.rb`): DSL for defining typed arguments on services.
- **ServiceBase::Types** (`lib/service_base/types.rb`): Type definitions module that includes dry-types.

### Service Pattern Implementation

Services follow the Railway Pattern using dry-monads:
- All services inherit from `ServiceBase::Service`
- Define arguments using `argument(:name, Type, description: "...")` DSL
- Implement `#call` method that returns `Success(value)` or `Failure(error)`
- Use `yield` for automatic failure bubbling in do-notation

### Generators

- **InstallGenerator** (`lib/generators/service_base/install_generator.rb`): Rails generator that creates ApplicationService base class and Type module
- **ApplicationServiceGenerator** (`lib/generators/application_service_generator.rb`): Creates `app/services/application_service.rb`
- **TypesGenerator** (`lib/generators/types_generator.rb`): Creates `app/models/type.rb` with ServiceBase::Types included

### Testing

- Uses RSpec with SimpleCov for coverage
- Test helpers available in `service_base/rspec` for stubbing service results
- Example services in `spec/support/` for testing patterns

## Key Patterns

### Service Definition
```ruby
class MyService < ApplicationService
  description("Does something useful")
  argument(:user, Type::User, description: "The user to process")
  argument(:data, Type::Hash, description: "Input data")

  def call
    # Use yield for automatic failure handling
    processed_data = yield process_data
    Success(processed_data)
  end

  private

  def process_data
    # Return Success/Failure monads
    Success(transformed_data)
  end
end
```

### Service Usage
```ruby
MyService.call(user: current_user, data: params) do |on|
  on.success { |result| handle_success(result) }
  on.failure { |error| handle_failure(error) }
end
```