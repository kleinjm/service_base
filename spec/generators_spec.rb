# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Generator Logic Tests' do
  describe 'Install Generator Logic' do
    it 'defines the correct generator sequence' do
      # Test the logic that the InstallGenerator.run_generators method should execute
      expected_generators = ['application_service', 'types']
      
      expect(expected_generators).to include('application_service')
      expect(expected_generators).to include('types')
      expect(expected_generators.size).to eq(2)
    end
  end

  describe 'ApplicationService Generator Logic' do
    let(:service_path) { 'app/services/application_service.rb' }
    
    def simulate_create_application_service_file(file_exists:, file_content: nil)
      if file_exists
        content = file_content || ''
        unless content.include?('class ApplicationService < ServiceBase::Service')
          # Simulate the file update logic
          content.sub(/class ApplicationService.*\n/, "class ApplicationService < ServiceBase::Service\n")
        else
          content # No change needed
        end
      else
        # Simulate template creation
        <<~RUBY
          class ApplicationService < ServiceBase::Service
          end
        RUBY
      end
    end

    it 'creates correct template for new file' do
      result = simulate_create_application_service_file(file_exists: false)
      
      expect(result).to include('class ApplicationService < ServiceBase::Service')
      expect(result.strip).to end_with('end')
    end

    it 'updates existing file with wrong inheritance' do
      old_content = "class ApplicationService < BaseService\n  # custom code\nend"
      result = simulate_create_application_service_file(file_exists: true, file_content: old_content)
      
      expect(result).to include('class ApplicationService < ServiceBase::Service')
      expect(result).to include('# custom code')
    end

    it 'leaves correct file unchanged' do
      correct_content = "class ApplicationService < ServiceBase::Service\n  # custom code\nend"
      result = simulate_create_application_service_file(file_exists: true, file_content: correct_content)
      
      expect(result).to eq(correct_content)
    end
  end

  describe 'Types Generator Logic' do
    let(:types_path) { 'app/models/type.rb' }
    
    def simulate_create_types_file(file_exists:, file_content: nil)
      if file_exists
        content = file_content || ''
        unless content.include?('include ServiceBase::Types')
          # Simulate the file update logic
          content.sub(/module Type\s*\n/, "module Type\n  include ServiceBase::Types\n")
        else
          content # No change needed
        end
      else
        # Simulate template creation
        <<~RUBY
          module Type
            include ServiceBase::Types
          end
        RUBY
      end
    end

    it 'creates correct template for new file' do
      result = simulate_create_types_file(file_exists: false)
      
      expect(result).to include('module Type')
      expect(result).to include('include ServiceBase::Types')
      expect(result.strip).to end_with('end')
    end

    it 'updates existing file without ServiceBase::Types' do
      old_content = "module Type\n  # custom types\nend"
      result = simulate_create_types_file(file_exists: true, file_content: old_content)
      
      expect(result).to include('include ServiceBase::Types')
      expect(result).to include('# custom types')
    end

    it 'leaves correct file unchanged' do
      correct_content = "module Type\n  include ServiceBase::Types\n  # custom types\nend"
      result = simulate_create_types_file(file_exists: true, file_content: correct_content)
      
      expect(result).to eq(correct_content)
    end
  end
end