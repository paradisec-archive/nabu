class EssenceDestructionService
  # remove file and db record(s)
  def self.destroy(essence)
    result = true

    response = Nabu::Catalog.instance.delete_essence(essence)
    result = false if response.code != '204'

    Rails.logger.info "[DELETE] Removed essence file at [#{essence.item.full_identifier}:#{essence.filename}"

    essence.destroy

    if result
      { notice: 'Essence removed successfully, and file deleted from archive (undo not possible).' }
    else
      { error: "Essence removed, but deleting file failed: #{response.message}" }
    end
  end
end
