class ValidateCatalogMediafluxJob < ApplicationJob
  queue_as :maintenance

  def perform
    CatalogMediafluxValidatorService.new.run
  end
end
