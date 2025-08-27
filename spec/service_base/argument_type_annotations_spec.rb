# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceBase::ArgumentTypeAnnotations do
  describe '.extended' do
    it 'raises TypeError when extended on non-Dry::Struct class' do
      regular_class = Class.new

      expect { regular_class.extend(ServiceBase::ArgumentTypeAnnotations) }
        .to raise_error(TypeError, /should be extended on a Dry::Struct subclass/)
    end

    it 'does not raise error when extended on Dry::Struct subclass' do
      struct_class = Class.new(Dry::Struct)

      expect { struct_class.extend(ServiceBase::ArgumentTypeAnnotations) }.not_to raise_error
    end
  end

  describe '.included' do
    it 'raises TypeError when included incorrectly' do
      regular_class = Class.new

      expect { regular_class.include(ServiceBase::ArgumentTypeAnnotations) }
        .to raise_error(TypeError, /should be included on the singleton class/)
    end

    it 'successfully extends Dry::Struct classes' do
      struct_class = Class.new(Dry::Struct)
      
      expect { struct_class.extend(ServiceBase::ArgumentTypeAnnotations) }.not_to raise_error
      expect(struct_class.respond_to?(:argument)).to be true
    end

    it 'includes Types in the attached object when included on singleton class' do
      struct_class = Class.new(Dry::Struct)
      singleton_class = struct_class.singleton_class
      
      # Manually call included to trigger the Types inclusion
      ServiceBase::ArgumentTypeAnnotations.included(singleton_class)
      
      # Verify Types constants are available on the struct class
      expect(struct_class.constants).to include(:String, :Boolean)
    end
  end

  describe '#argument' do
    let(:test_service) do
      Class.new(ServiceBase::Service) do
        def call
          Success('test')
        end
      end
    end

    describe 'mutable default validation' do
      it 'raises ArgumentError for mutable default values' do
        expect do
          test_service.argument(:mutable_default, Type::Array, default: [])
        end.to raise_error(ArgumentError, /is mutable.*Please `.freeze`/)
      end

      it 'allows frozen default values' do
        expect do
          test_service.argument(:frozen_default, Type::Array, default: [].freeze)
        end.not_to raise_error
      end

      it 'allows immutable default values' do
        expect do
          test_service.argument(:string_default, Type::String, default: 'test')
        end.not_to raise_error
      end
    end

    describe 'optional and default validation' do
      it 'raises ArgumentError when both optional and default are specified' do
        expect do
          test_service.argument(:bad_arg, Type::String, optional: true, default: 'test')
        end.to raise_error(ArgumentError, /cannot specify both a default value and optional: true/)
      end

      it 'allows optional without default' do
        expect do
          test_service.argument(:optional_arg, Type::String, optional: true)
        end.not_to raise_error
      end

      it 'allows default without optional flag' do
        expect do
          test_service.argument(:default_arg, Type::String, default: 'test')
        end.not_to raise_error
      end
    end

    describe 'enum type handling' do
      it 'handles enum types with defaults when constantize is available' do
        # Add constantize method to String for this test
        String.class_eval do
          def constantize
            case self
            when 'Types::String'
              Type::String
            else
              raise NameError, "uninitialized constant #{self}"
            end
          end
        end
        
        enum_values = ['option1', 'option2']
        enum_type = Type::String.enum(*enum_values)
        
        test_service.argument(:enum_arg, enum_type, default: 'option1')
        
        service_instance = test_service.new
        expect(service_instance.enum_arg).to eq('option1')
      ensure
        # Clean up the method we added
        String.class_eval do
          undef_method :constantize if method_defined?(:constantize)
        end
      end

      it 'raises error when trying to set default on enum without constantize available' do
        enum_values = ['option1', 'option2'] 
        enum_type = Type::String.enum(*enum_values)
        
        # This will trigger the enum handling path in set_default but fail due to missing constantize
        expect do
          test_service.argument(:enum_arg, enum_type, default: 'option1')
        end.to raise_error(NoMethodError, /undefined method.*constantize/)
      end

      it 'handles non-enum types with defaults normally' do
        test_service.argument(:string_arg, Type::String, default: 'default_value')
        
        service_instance = test_service.new
        expect(service_instance.string_arg).to eq('default_value')
      end
    end

    describe 'description handling' do
      it 'sets description to nil when empty string provided' do
        test_service.argument(:test_arg, Type::String, description: '')
        schema_def = test_service.send(:schema_definition).find { |arg| arg[:name] == :test_arg }
        
        expect(schema_def[:description]).to be_nil
      end

      it 'preserves non-empty descriptions' do
        test_service.argument(:test_arg, Type::String, description: 'A test argument')
        schema_def = test_service.send(:schema_definition).find { |arg| arg[:name] == :test_arg }
        
        expect(schema_def[:description]).to eq('A test argument')
      end
    end
  end
end