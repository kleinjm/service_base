# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/application_service'

RSpec.describe ServiceBase::Service do
  class ExampleService < ApplicationService
    description 'An example service'

    argument(:succeeds, Type::Boolean, default: true, description: 'Whether the service should succeed')
    argument(:dry_time, Type::Time, optional: true, description: 'Time from the dry-types gem')
    argument(:example_model, Type::ExampleModel, optional: true, description: 'An example model')

    def call
      if succeeds
        # Check that namespacing is working as expected and not conflicting with the `Type` module
        ExampleModel.do_nothing
        Time.now

        Success(arguments)
      else
        Failure('failure')
      end
    end
  end

  describe '#arguments' do
    it 'returns a hash of the arguments' do
      expect(ExampleService.call.success).to eq({ succeeds: true })
    end
  end

  describe '#call' do
    it 'returns a result' do
      expect(ExampleService.call).to be_success
      expect(ExampleService.call.success).to eq({ succeeds: true })
    end

    it 'raises Dry::Matcher::ResultMatcher::FailedError when the call to the service unwraps success but not failure' do
      expect do
        ExampleService.call do |on|
          on.success { true }
        end
      end.to raise_error(Dry::Matcher::NonExhaustiveMatchError)
    end
  end

  describe '#call!' do
    it 'forwards the result when the call to the service succeeds' do
      result = ExampleService.call!

      expect(result).to be_success
      expect(result.success).to eq({ succeeds: true })
    end

    it 'raises an error when the call to the service fails' do
      expect { ExampleService.call!(succeeds: false) }
        .to raise_error(ApplicationService::ServiceNotSuccessful) { |error| expect(error.failure).to eq('failure') }
    end
  end

  describe '#service_description' do
    it 'returns the description' do
      expect(ExampleService.service_description).to eq('An example service')
    end
  end

  describe '#pp' do
    it 'returns a string representation of the service' do
      logger = double
      allow(Logger).to receive(:new).and_return(logger)
      allow(logger).to receive(:info)

      ExampleService.pp

      expect(logger).to have_received(:info).with('ExampleService: An example service')
      expect(logger).to have_received(:info).with('Arguments')
      expect(logger).to have_received(:info).with('  succeeds (TrueClass | FalseClass): Whether the service should succeed')
    end

    it 'handles services without descriptions' do
      service_without_description = Class.new(ApplicationService) do
        argument(:test_arg, Type::String, description: 'A test argument')
      end

      logger = double
      allow(Logger).to receive(:new).and_return(logger)
      allow(logger).to receive(:info)

      service_without_description.pp

      expect(logger).to have_received(:info).with("#{service_without_description.name}: No description")
    end
  end

  describe 'base call method' do
    it 'raises NotImplementedError when call is not implemented' do
      service = Class.new(ServiceBase::Service)
      expect { service.new.send(:call) }.to raise_error(NotImplementedError)
    end
  end

  describe 'ServiceNotSuccessful exception' do
    it 'stores the failure and has a default message' do
      failure_value = 'test failure'
      exception = ServiceBase::Service::ServiceNotSuccessful.new(failure_value)
      
      expect(exception.failure).to eq(failure_value)
      expect(exception.message).to eq('Failed to call service')
    end
  end

  describe 'argument validation' do
    it 'raises error for invalid arguments' do
      expect { ExampleService.call(invalid_arg: 'value') }.to raise_error(ArgumentError, /provided invalid arguments: invalid_arg/)
    end
  end
end
