class MintDoisJob < ApplicationJob
  queue_as :maintenance

  class MintingFailed < StandardError; end

  def perform
    failed = BatchDoiMintingService.run(false)
    return if failed.empty?

    named = failed.first(10).map(&:full_path)
    named << "and #{failed.size - named.size} more" if failed.size > named.size

    raise MintingFailed, "Failed to mint DOIs for #{failed.size} objects: #{named.join(', ')}"
  end
end
