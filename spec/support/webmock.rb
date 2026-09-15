require 'webmock/rspec'

# OpenSearch and the S3 mock are real services in the test stack; everything else must be stubbed.
test_stack_hosts = [ENV.fetch('OPENSEARCH_URL', nil), ENV.fetch('S3_ENDPOINT', 'http://s3:9090')].compact.map { |url| URI(url).host }

WebMock.disable_net_connect!(allow_localhost: true, allow: test_stack_hosts)
