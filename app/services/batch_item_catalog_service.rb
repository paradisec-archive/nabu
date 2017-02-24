class BatchItemCatalogService
  def self.run(offline_template)
    batch_item_catalog_service = new(offline_template)
    batch_item_catalog_service.run
  end

  def initialize(offline_template)
    @offline_template = offline_template
  end

  def run
    Item.find_each do |item|
      process_item(item)
    end
  end

  def process_item(item)
    ItemCatalogService.new(item).delay.save_file
  end
end
