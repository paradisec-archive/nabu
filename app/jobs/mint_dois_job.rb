class MintDoisJob < ApplicationJob
  queue_as :maintenance

  class MintingFailed < StandardError; end

  def perform
    failed = BatchDoiMintingService.run(false)
    return if failed.empty?

    listed = failed.first(10).map(&:full_path)
    listed << "and #{failed.size - listed.size} more" if failed.size > listed.size

    raise MintingFailed, "Failed to mint DOIs for #{failed.size} objects: #{listed.join(', ')}"
  end
end
