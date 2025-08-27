# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceBase::Types do
  let(:test_module) do
    Module.new do
      include ServiceBase::Types
    end
  end

  it 'includes Dry.Types functionality' do
    expect(test_module::String).to eq(Dry::Types['string'])
    expect(test_module::Integer).to eq(Dry::Types['integer'])
  end

  it 'provides Boolean alias for bool type' do
    expect(test_module::Boolean).to eq(Dry::Types['bool'])
  end

  it 'makes key Dry::Types constants available' do
    expect(test_module::String).to respond_to(:call)
    expect(test_module::Integer).to respond_to(:call)
    expect(test_module::Array).to respond_to(:call)
    expect(test_module::Hash).to respond_to(:call)
  end

  describe 'when included' do
    it 'copies constants to the including module' do
      including_module = Module.new
      including_module.include(ServiceBase::Types)

      expect(including_module::String).to eq(Dry::Types['string'])
      expect(including_module::Boolean).to eq(Dry::Types['bool'])
    end
  end
end