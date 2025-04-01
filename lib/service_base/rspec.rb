# frozen_string_literal: true

# relative-require all rspec files
Dir[File.dirname(__FILE__) + '/rspec/*.rb'].each do |file|
  require 'base_service/rspec/' + File.basename(file, File.extname(file))
end
