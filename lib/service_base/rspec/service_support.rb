# frozen_string_literal: true

module ServiceSupport
  # Note that you must have at least one `on.success` and one `on.failure`
  # matcher for each block-style service call
  def stub_service_success(service_class, success: nil)
    block = double(:on)
    allow(block).to receive(:failure)
    if success.present?
      allow(block).to receive(:success).and_yield(success)
    else
      allow(block).to receive(:success)
    end
    allow(service_class).to receive(:call).and_yield(block)
  end

  # Note that you must have at least one `on.success` and one `on.failure`
  # matcher for each block-style service call.
  # Set `matched: true` for specific `on.failure(:error)` blocks.
  # Set `matched: true` for catch-all `on.failure` blocks.
  def stub_service_failure(service_class, failure:, matched: false)
    block = double(:on)
    allow(block).to receive(:success)
    if matched # on.failure(:some_error)
      allow(block).to receive(:failure) # ignore unmatched on.failure
      allow(block).to receive(:failure).with(failure).and_yield(failure)
    else # on.failure
      # ignore matched on.failure(:some_error)
      allow(block).to receive(:failure).with(anything)
      allow(block).to receive(:failure).with(no_args).and_yield(failure)
    end
    allow(service_class).to receive(:call).and_yield(block)
  end
end

RSpec.configure do |config|
  config.include ServiceSupport
end
