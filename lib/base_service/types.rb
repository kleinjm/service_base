# frozen_string_literal: true

# Defines Dry Types. These Types are included in the BaseService for type
# enforcement when defining `argument`s.
#
# For example, you may want to add `ApplicationRecord = Types.Instance(ApplicationRecord)`
#
# Add custom types as outlined in
# https://dry-rb.org/gems/dry-types/1.2/custom-types/

require 'dry-types'

module Types
  include Dry.Types()

  UpCasedString = Types::String.constructor(&:upcase)
  Boolean = Bool # alias the built in type, Bool
end
