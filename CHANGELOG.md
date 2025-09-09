# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-09-09

### Added
- Support for parameter-less failure and success handlers in ServiceSupport test helpers
- Flexible block parameter handling that works with both `on.failure { |error| ... }` and `on.failure do ... end` patterns
- Comprehensive test coverage for parameter-less handler scenarios
- New helper methods in ServiceSupport for improved code organization

### Changed  
- Refactored ServiceSupport methods to use helper methods for better maintainability
- Enhanced ServiceSupport stubbing to automatically detect block parameter requirements
- Improved error handling in test stubs with fallback to parameter-less calls

### Technical Details
- ServiceSupport methods now use Ruby's `ArgumentError` rescue mechanism to detect block parameter compatibility
- `stub_service_success` and `stub_service_failure` automatically handle both parameterized and parameter-less blocks
- Test stubs try calling with parameters first, then fall back to parameter-less calls when blocks don't accept them
- This enables cleaner test code without requiring unused `|_|` parameters in failure handlers

## [1.0.4] - 2025-08-27

### Added
- Comprehensive test coverage achieving 100%
- GitHub Actions workflow for running tests
- GitHub Actions status badge to README

### Changed
- Improved README formatting and clarity

### Fixed
- GitHub Actions workflow compatibility with Rails 8.0+

## [1.0.3] - 2025-04-30

### Fixed
- ServiceSupport now properly yields success block values in stubbed services

## [1.0.2] - 2025-04-24

### Changed
- Improved constant namespacing to avoid need for global search with `::`
- Fixed generator issues for proper file creation

### Fixed
- Type generator now works correctly
- Generator template improvements

## [1.0.1] - 2025-04-02

### Changed
- Removed types and locale support to simplify the gem
- Improved namespacing - everything now properly namespaced to `ServiceBase::`
- Enhanced test coverage

### Removed
- Active Support dependency for lighter footprint
- Locale support functionality
- Custom types functionality

## [1.0.0] - 2025-04-01

### Added
- Initial release of ServiceBase gem
- Service Object pattern implementation with dry-rb integration
- Railway-oriented programming using dry-monads
- Type validation using dry-struct and dry-types
- ArgumentTypeAnnotations DSL for service arguments
- Service generators for Rails integration
- RSpec test helpers with ServiceSupport
- Comprehensive documentation and examples

### Features
- Base Service class with automatic type validation
- Result monad integration (Success/Failure)
- Service description and pretty-printing support
- Rails generators for ApplicationService and Type modules
- Test stubbing utilities for service success/failure scenarios
- Argument validation with descriptive error messages