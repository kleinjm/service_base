# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'base_service'
  spec.version       = BaseService::VERSION
  spec.authors       = ['James Klein']
  spec.email         = ['kleinjm007@gmail.com']

  spec.summary       = 'A base service class for Ruby applications'
  spec.description   = 'A base service class for Ruby applications with argument type annotations and railway-oriented programming'
  spec.homepage      = 'https://github.com/kleinjm/base_service'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob('{lib}/**/*') + %w[README.md LICENSE.txt]
  spec.require_paths = ['lib']

  spec.add_dependency 'dry-matcher', '~> 0.8.0'
  spec.add_dependency 'dry-monads', '~> 1.6'
  spec.add_dependency 'dry-struct', '~> 1.6'
  spec.add_dependency 'dry-types', '~> 1.7'
  spec.add_dependency 'memery', '~> 1.7'
end
