class BatchItemCatalogService
  def self.run(offline_template, dry_run)
    batch_item_catalog_service = new(offline_template, dry_run)
    batch_item_catalog_service.run
  end

  def initialize(offline_template, dry_run)
    @offline_template = offline_template
    @dry_run = dry_run
  end

  def run
    Item.find_each do |item|
      process_item(item)
    end
  end

  def process_item(item)
    if @dry_run
      puts "Would generate catalog file for item #{item.id}"
    else
      ItemCatalogService.new(item).delay.save_file
    end
  end
end
