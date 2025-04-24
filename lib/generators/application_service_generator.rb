# frozen_string_literal: true

class ApplicationServiceGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  def create_application_service_file
    service_path = 'app/services/application_service.rb'

    if File.exist?(service_path)
      # File exists, check if it needs to be updated
      content = File.read(service_path)

      unless content.include?('class ApplicationService < ServiceBase::Service')
        # Update the class definition
        new_content = content.sub(/class ApplicationService.*\n/, "class ApplicationService < ServiceBase::Service\n")
        File.write(service_path, new_content)
      end
    else
      # Create new file with template
      create_file service_path, <<~RUBY
        class ApplicationService < ServiceBase::Service
        end
      RUBY
    end
  end
end
