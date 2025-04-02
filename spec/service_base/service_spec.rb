# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceBase::Service do
  class ApplicationService < ServiceBase::Service
  end

  class ExampleService < ApplicationService
    description 'An example service'

    argument(:succeeds, Bool, default: true, description: 'Whether the service should succeed')

    def call
      if succeeds
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
  end
end
