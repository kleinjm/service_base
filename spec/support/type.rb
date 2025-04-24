require_relative './example_model'

module Type
  include ServiceBase::Types

  # Models
  ExampleModel = Dry.Types.Instance(ExampleModel)
end
