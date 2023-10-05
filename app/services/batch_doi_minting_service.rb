# Batch minting of DOIs.
# For an individual minting, see DoiMintingService.

class BatchDoiMintingService
  def self.run(batch_size, dry_run)
    batch_doi_minting_service = new(batch_size, dry_run)
    batch_doi_minting_service.run
  end

  def initialize(batch_size, dry_run)
    @batch_size = batch_size
    @dry_run = dry_run
    @doi_minting_service = create_doi_minting_service
    @unminted_objects = find_unminted_objects
  end

  def create_doi_minting_service
    DoiMintingService.new(@dry_run)
  end

  # The way this find works ensures that the minting occurs in a top-down manner allowing for
  # Items and Essences to reference their parent records by DOI
  def find_unminted_objects
    # OPTIMIZATION: This isn't optimized for saving a lot of objects, but when eager loaded is added,
    # the amount of memory consumed is unacceptably large.
    (
      Collection
        .where(doi: nil, private: false).includes(:collector, :university).limit(@batch_size) +
      Item
        .joins(:collection).where(doi: nil, private: false, collections: { private: false }).includes(:collector, :university, :collection).limit(@batch_size) +
      Essence
        .includes(item: %i[collector collection]).where(doi: nil, items: { private: false, collections: { private: false } }).limit(@batch_size)
    ).first(@batch_size)
  end

  def run
    Rails.logger.info "Start Minting: #{Time.current}"
    @unminted_objects.each do |unminted_object|
      next unless public_object?(unminted_object)

      @doi_minting_service.mint_doi(unminted_object)
    end
    Rails.logger.info "Finished Minting: #{Time.current}"
  end

  # This is the canonical source of information on whether an object is public, as far as BatchDoiMintingService
  # is concerned. The private: false in find_unminted_objects is to ensure we don't end up with
  # @batch_size unmintable objects and no mintable objects.
  def public_object?(unminted_object)
    # Refactor: If too much code tests whether a collection is public or not, consider implementing
    # Collection#public?, akin to Item#public?
    # Refactor: Also consider Essence#public? if too much code tests whether an essence is public or not.
    case unminted_object
    when Collection
      unminted_object.private == false
    when Item
      unminted_object.public?
    when Essence
      unminted_object.item.public?
    else
      # Shouldn't happen. Default to not minting.
      false
    end
  end
end
