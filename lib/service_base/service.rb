# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'dry/matcher/result_matcher'
require 'dry-struct'
require 'dry-matcher'
require 'memery'

module ServiceBase
  class Service < Dry::Struct
    extend Dry::Monads::Result::Mixin::Constructors
    include Dry::Monads::Do.for(:call)
    include Dry::Monads[:result, :do]

    extend ArgumentTypeAnnotations
    include Memery

    class ServiceNotSuccessful < StandardError
      attr_reader(:failure)

      def initialize(failure)
        super('Failed to call service')
        @failure = failure
      end
    end

    class << self
      # The public class call method.
      #
      # The default empty hash is important to prevent an argument error when
      # passing no arguments to a service that defines defaults for every argument.
      def call(args = {}, &block)
        validate_args!(args: args)

        result = new(args).call
        match_result(result, &block)
      end

      def call!(*args)
        result = call(*args)
        raise(ServiceNotSuccessful, result.failure) if result.failure?

        result
      end

      # Pretty prints (pp) the description of the service, ie. `MyService.pp`
      def pp
        logger = Logger.new($stdout)
        logger.info("#{name}: #{service_description}")
        logger.info('Arguments')

        schema_definition.each do |arg|
          logger.info("  #{arg[:name]} (#{arg[:type]}): #{arg[:description]}")
        end
      end

      # @description getter
      def service_description
        @description || 'No description'
      end

      private

      # Set the description on the service
      def description(text)
        @description = text
      end

      # Employs ResultMatcher to unwrap values using `on.success` & `on.failure`
      # syntax. If not using block form to extract the result of a service,
      # ie. `MyService.call.fmap { |result| result + 2 }`, ensure you explictly
      # handle Failures. See https://dry-rb.org/gems/dry-monads/1.3/result/
      def match_result(result, &block)
        # https://medium.com/swlh/better-rails-service-objects-with-dry-rb-702687394e3d
        if block
          # raises Dry::Matcher::NonExhaustiveMatchError: cases +failure+ not handled
          # if `on.failure` is not declared
          Dry::Matcher::ResultMatcher.call(result, &block)
        else
          result
        end
      end

      # Introspects the arguments DSL to extract information on each argument
      def schema_definition
        attribute_names.each_with_object([]) do |attribute_name, list|
          dry_type = schema.key(attribute_name)
          list << {
            name: attribute_name,
            description: dry_type.meta[:description],
            type: dry_type.type.name
          }
        end
      end
    end

    # Returns a hash of all arguments and their values
    def arguments
      attributes
    end

    private

    # The call method that must be defined by every inheriting service class
    def call
      raise(NotImplementedError)
    end
  end
end
