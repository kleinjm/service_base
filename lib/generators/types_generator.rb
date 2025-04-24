# frozen_string_literal: true

class TypesGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  def create_types_file
    types_path = 'app/models/types.rb'

    if File.exist?(types_path)
      # File exists, check if it needs the include statement
      content = File.read(types_path)

      unless content.include?('include ServiceBase::Type')
        # Add include statement at the top of the module
        new_content = content.sub(/module Type\s*\n/, "module Type\n  include ServiceBase::Types\n")
        File.write(types_path, new_content)
      end
    else
      # Create new file with template
      create_file types_path, <<~RUBY
        module Type
          include ServiceBase::Types
        end
      RUBY
    end
  end
end
