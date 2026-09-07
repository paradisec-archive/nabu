class ValidateCatalogReplicationJob < ApplicationJob
  queue_as :maintenance

  def perform
    CatalogReplicationValidatorService.new.run
  end
end
