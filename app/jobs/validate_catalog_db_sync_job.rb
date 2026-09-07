class ValidateCatalogDbSyncJob < ApplicationJob
  queue_as :maintenance

  def perform
    CatalogDbSyncValidatorService.new('prod').run
  end
end
