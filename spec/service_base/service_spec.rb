# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceBase::Service do
  class ApplicationService < ServiceBase::Service
  end

  describe 'call!' do
    it 'forwards the result when the call to the service succeeds' do
      service = Class.new(ApplicationService) do
        def call
          Success('success')
        end
      end

      result = service.call!

      expect(result).to be_success
      expect(result.success).to eq('success')
    end

    it 'raises an error when the call to the service fails' do
      service = Class.new(ApplicationService) do
        argument(:should_fail, ServiceBase::Types::Boolean)

        def call
          Failure('failure') if should_fail
        end
      end

      expect { service.call!(should_fail: true) }
        .to raise_error(ApplicationService::ServiceNotSuccessful) { |error| expect(error.failure).to eq('failure') }
    end
  end
end
