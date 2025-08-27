# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ServiceBase RSpec integration' do
  it 'loads RSpec support files automatically' do
    expect { require 'service_base/rspec' }.not_to raise_error
  end

  it 'makes ServiceSupport methods available in test context' do
    require 'service_base/rspec'
    
    expect(self.respond_to?(:stub_service_success)).to be true
    expect(self.respond_to?(:stub_service_failure)).to be true
  end
end