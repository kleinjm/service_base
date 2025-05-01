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
end
