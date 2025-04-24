# frozen_string_literal: true

module ServiceBase
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def run_generators
      generate 'application_service'
      generate 'types'
    end
  end
end
