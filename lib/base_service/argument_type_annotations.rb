# frozen_string_literal: true

module ArgumentTypeAnnotations
  class << self
    def extended(klass)
      if !klass.is_a?(Class) || klass.ancestors.exclude?(Dry::Struct)
        raise(TypeError, "#{name} should be extended on a Dry::Struct subclass")
      end

      # `Types` overrides default types to help shorthand Type::String.
      # To access Ruby's native types within a service, use `::`, ie. `::String`
      klass.include(Types)
    end

    def included(klass)
      if !klass.singleton_class? || klass.attached_object.ancestors.exclude?(Dry::Struct)
        raise(TypeError, "#{name} should be included on the singleton class of a Dry::Struct subclass")
      end

      # `Types` overrides default types to help shorthand Type::String.
      # To access Ruby's native types within a service, use `::`, ie. `::String`
      klass.attached_object.include(Types)
    end
  end

  # Defines an argument using the BaseService DSL.
  # Under the hood, this uses dry-struct's attribute DSL.
  def argument(name, type, configuration = {}, &)
    description = configuration[:description].presence
    type = type.meta(description:)

    default = configuration[:default]
    validate_frozen_default!(name:, default:)

    optional = configuration.fetch(:optional, false)
    validate_optional_or_default!(optional:, default:, name:)

    type = set_default(type:, default:)

    if optional
      # attribute? allows the key to be omitted.
      # .optional allows the value to be nil.
      # https://dry-rb.org/gems/dry-types/1.2/optional-values/
      # https://github.com/dry-rb/dry-struct/blob/master/lib/dry/struct/class_interface.rb#L141-L169
      attribute?(name, type.optional, &)
    else
      # https://github.com/dry-rb/dry-struct/blob/master/lib/dry/struct/class_interface.rb#L30-L104
      attribute(name, type, &)
    end
  end

  private

  # Raises a warning from dry-types to avoid memory sharing.
  # https://github.com/dry-rb/dry-types/blob/master/lib/dry/types/builder.rb#L71-L81
  def validate_frozen_default!(name:, default:)
    return if default.frozen?

    raise(
      ArgumentError,
      "#{default} provided as a default value for #{name} is mutable. " \
      "Please `.freeze` your `default:` input.",
    )
  end

  # Do not allow setting both a default value and optional: true. If both
  # are specified, the default will not be used.
  def validate_optional_or_default!(optional:, default:, name:)
    return unless optional && !default.nil?

    raise(
      ArgumentError,
      "#{name} cannot specify both a default value and optional: true. " \
      "Only specify a default value if the value is optional.",
    )
  end

  # Ensures that provided args are declared as `argument`s
  def validate_args!(args:)
    invalid_args = (args.keys - attribute_names)
    return if invalid_args.blank?

    raise(
      ArgumentError,
      "#{self} provided invalid arguments: #{invalid_args.join(', ')}",
    )
  end

  # Sets the default value on the type.
  # For primitive types, the default can be set after initialization.
  # For enums, the default must be set during initialization. Therefore,
  # we must check the type of the enum and then reconstruct the enum with
  # the default value being set.
  # See "Note" in https://dry-rb.org/gems/dry-types/1.2/enum/
  def set_default(type:, default:)
    return type if default.nil?

    if type.is_a?(Dry::Types::Enum)
      values = type.values
      type_class = "Types::#{values.first.class}".constantize
      type_class.default(default).enum(*values)
    else
      type.default(default)
    end
  end
end
