# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/service_base/rspec/service_support'

RSpec.describe ServiceSupport do
  include ServiceSupport

  class TestService < ServiceBase::Service
    def call
      Success('Some value')
    end
  end

  def call_service_without_value
    TestService.call do |on|
      on.success { return 'Success' }
      on.failure { raise 'Should not be called' }
    end
  end

  def call_service_with_value
    TestService.call do |on|
      on.success { |value| return value }
      on.failure { raise 'Should not be called' }
    end
  end

  describe '#stub_service_success' do
    it 'stubs the service success and disregards the value' do
      stub_service_success(TestService)

      expect(call_service_without_value).to eq('Success')
    end

    it 'stubs the service success with a stubbed value' do
      stub_service_success(TestService, success: 'A different value')

      expect(call_service_with_value).to eq('A different value')
    end

    it 'stubs the service success with nil as the success value' do
      stub_service_success(TestService, success_nil: true)

      expect(call_service_with_value).to eq(nil)
    end
  end

  describe '#stub_service_failure' do
    def call_service_with_failure_handling
      TestService.call do |on|
        on.success { raise 'Should not be called' }
        on.failure { |error| return error }
      end
    end

    def call_service_with_matched_failure
      TestService.call do |on|
        on.success { raise 'Should not be called' }
        on.failure(:specific_error) { |error| return "Matched: #{error}" }
        on.failure { |error| return "Unmatched: #{error}" }
      end
    end

    it 'stubs service failure with catch-all failure block' do
      stub_service_failure(TestService, failure: 'test error')

      expect(call_service_with_failure_handling).to eq('test error')
    end

    it 'stubs service failure with matched specific error' do
      stub_service_failure(TestService, failure: :specific_error, matched: true)

      expect(call_service_with_matched_failure).to eq('Matched: specific_error')
    end
  end
end
