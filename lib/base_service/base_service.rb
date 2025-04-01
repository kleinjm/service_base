# frozen_string_literal: true

require "dry-matcher"
require "dry-struct"
require "dry/matcher/result_matcher"
require "dry/monads"
require "dry/monads/do"

# Please read: https://www.notion.so/patchtech/BaseService-README-2bc7fb23a83a470eb2a108abfbbf72ec
class BaseService < Dry::Struct
  extend Dry::Monads::Result::Mixin::Constructors
  include Dry::Monads::Do.for(:call)
  include Dry::Monads[:result, :do]

  extend ArgumentTypeAnnotations
  include Memery

  class ServiceNotSuccessful < StandardError
    attr_reader(:failure)

    def initialize(failure)
      super("Failed to call service")
      @failure = failure
    end
  end

  class << self
    # The public class call method.
    #
    # The default empty hash is important to prevent an argument error when
    # passing no arguments to a service that defines defaults for every argument.
    def call(args = {}, &)
      validate_args!(args:)

      result = new(args).call
      match_result(result, &)
    end

    def call!(...)
      result = call(...)
      raise(ServiceNotSuccessful, result.failure) if result.failure?

      result
    end

    # Pretty prints (pp) the description of the service, ie. `MyService.pp`
    def pp
      logger = Logger.new($stdout)
      logger.info("#{name}: #{service_description}")
      logger.info("Arguments")

      schema_definition.each do |arg|
        logger.info("  #{arg[:name]} (#{arg[:type]}): #{arg[:description]}")
      end
    end

    # @description getter
    def service_description
      @description || "No description"
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
          type: dry_type.type.name,
        }
      end
    end
  end

  # Given a project and an organization, return an array of project inventory
  # IDs that are allowed to be ordered/purchased by the organization.
  def allowed_project_inventory_ids(project_id:, organization:)
    # Determine the accessible project inventories for the project and pass
    # them into the service to ensure a visible project inventory is selected
    policy_context = UserContext.new(organization:)
    project_inventory = ProjectInventoryPolicy::ConsumerBaseScope.new(
      policy_context,
      ProjectInventory,
    ).resolve
    project_inventory.where(project_id:).pluck(:id)
  end

  # Return a ResponseFailure
  def ResponseFailure(message, code) # rubocop:disable Naming/MethodName
    trace_caller = Dry::Monads::RightBiased::Left.trace_caller
    ResponseFailure.new(message, code, trace_caller)
  end

  private

  # The call method that must be defined by every inheriting service class
  def call
    raise(NotImplementedError)
  end

  # A locale lookup helper that uses the name of the service
  def locale(selector, args = {})
    class_name = self.class.name.gsub("::", ".").underscore
    I18n.t(".#{selector}", scope: "services.#{class_name}", **args)
  end

  # Structured Monad Result Failure type for returning a ResponseError
  class ResponseFailure < Dry::Monads::Result::Failure
    def initialize(
      message, code,
      trace = Dry::Monads::RightBiased::Left.trace_caller
    )
      super(ResponseError.new(message:, code:), trace)
    end
  end
end
