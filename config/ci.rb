# Run using bin/ci

CI.run do
  step 'Style: Ruby', 'bin/rubocop'

  step 'Security: Brakeman code analysis', 'bin/brakeman --quiet --no-pager'
  step 'Security: Gem audit', 'bin/bundle-audit'

  step 'Tests: RSpec', 'bin/test'
end
