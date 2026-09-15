require 'webmock/rspec'

# OpenSearch and the S3 mock are real services in the test stack, so the network stays open unless
# a spec opts in with `:webmock`, where any request without a stub fails.
WebMock.allow_net_connect!

RSpec.configure do |config|
  config.around(:each, :webmock) do |example|
    WebMock.disable_net_connect!
    example.run
  ensure
    WebMock.allow_net_connect!
  end
end
