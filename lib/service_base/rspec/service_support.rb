# frozen_string_literal: true

module ServiceSupport
  # Note that you must have at least one `on.success` and one `on.failure`
  # matcher for each block-style service call
  def stub_service_success(service_class, success: nil, success_nil: false)
    block = double(:on)
    allow(block).to receive(:failure)

    yield_value = determine_success_yield_value(success, success_nil)
    allow(block).to receive(:success) { |&block_proc| call_with_flexible_params(block_proc, yield_value) }
    allow(service_class).to receive(:call).and_yield(block)
  end

  # Note that you must have at least one `on.success` and one `on.failure`
  # matcher for each block-style service call.
  # Set `matched: true` for specific `on.failure(:error)` blocks.
  # Set `matched: true` for catch-all `on.failure` blocks.
  def stub_service_failure(service_class, failure:, matched: false)
    block = double(:on)
    allow(block).to receive(:success)

    setup_failure_stub(block, failure, matched)
    allow(service_class).to receive(:call).and_yield(block)
  end

  private

  def determine_success_yield_value(success, success_nil)
    return success unless success.nil?
    return nil if success_nil

    :no_yield
  end

  def call_with_flexible_params(block_proc, yield_value)
    if yield_value == :no_yield
      block_proc.call
    else
      call_block_with_fallback(block_proc, yield_value)
    end
  end

  def call_block_with_fallback(block_proc, value)
    block_proc.call(value)
  rescue ArgumentError
    # Block doesn't accept parameters, call without arguments
    block_proc.call
  end

  def setup_failure_stub(block, failure, matched)
    if matched
      setup_matched_failure_stub(block, failure)
    else
      setup_unmatched_failure_stub(block, failure)
    end
  end

  def setup_matched_failure_stub(block, failure)
    allow(block).to receive(:failure) # ignore unmatched on.failure
    allow(block).to receive(:failure).with(failure) do |&failure_block|
      call_block_with_fallback(failure_block, failure)
    end
  end

  def setup_unmatched_failure_stub(block, failure)
    # ignore matched on.failure(:some_error)
    allow(block).to receive(:failure).with(anything)
    allow(block).to receive(:failure).with(no_args) do |&failure_block|
      call_block_with_fallback(failure_block, failure)
    end
  end
end

RSpec.configure do |config|
  config.include ServiceSupport
end
