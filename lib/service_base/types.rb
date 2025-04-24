require 'dry-types'

module ServiceBase
  module Types
    include Dry.Types()

    def self.included(base)
      constants.each { |constant| base.const_set(constant, const_get("#{self}::#{constant}")) }
    end

    # Alias Bool -> Boolean
    Boolean = Dry::Types['bool']
  end
end
