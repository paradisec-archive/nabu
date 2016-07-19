# Batch minting of DOIs.
# For an individual minting, see DoiMintingService.
class BatchDoiMintingService
  def self.run(batch_size)
    batch_doi_minting_service = new(batch_size)
    batch_doi_minting_service.run
  end

  def initialize(batch_size)
    @batch_size = batch_size
    @doi_minting_service = create_doi_minting_service
    @unminted_objects = find_unminted_objects
  end

  def create_doi_minting_service
    DoiMintingService.new('json')
  end

  # The way this find works ensures that the minting occurs in a top-down manner allowing for
  # Items and Essences to reference their parent records by DOI
  def find_unminted_objects
    (
      Collection.where(doi: nil, private: false).includes(:collector, :university).limit(@batch_size) +
      Item.joins(:collection).where(doi: nil, private: false, collection: {private: false}).includes(:collector, :university, :collection).limit(@batch_size) +
      Essence.where(doi: nil).includes(item: [:collector]).limit(@batch_size)
    ).first(@batch_size)
  end

  def run
    @unminted_objects.each do |unminted_object|
      next unless public_object?(unminted_object)
      @doi_minting_service.mint_doi(unminted_object)
    end
  end

  # This is the canonical source of information on whether an object is public, as far as BatchDoiMintingService
  # is concerned. The private: false in find_unminted_objects is to ensure we don't end up with
  # @batch_size unmintable objects and no mintable objects.
  def public_object?(unminted_object)
    # Refactor: If too much code tests whether a collection is public or not, consider implementing
    # Collection#public?, akin to Item#public?
    case unminted_object
    when Collection
      unminted_object.private == false
    when Item
      unminted_object.public?
    else
      # Shouldn't happen. Default to not minting.
      false
    end
  end
end
