require 'stringio'

module ExpectationHelpers
  def capture_stdout(&block)
    old = $stdout
    $stdout = fake = StringIO.new

    block.call
    fake.string
  ensure
    $stdout = old
  end

  def capture_stderr(&block)
    old = $stderr
    $stderr = fake = StringIO.new

    block.call
    fake.string
  ensure
    $stderr = old
  end
end
