# Run using bin/ci

CI.run do
  step 'Style: Ruby', 'bin/rubocop'

  step 'Security: Brakeman code analysis', 'bin/brakeman --quiet --no-pager'
  step 'Security: Gem audit', 'bin/bundle-audit'

  # Every step runs unless guarded, and the suite takes minutes
  if success?
    step 'Tests: RSpec', 'bin/test'
  else
    failure 'Tests: RSpec skipped', 'Fix the failures above, then run bin/ci again.'
  end
end
