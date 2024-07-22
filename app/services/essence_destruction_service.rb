class EssenceDestructionService
  # remove file and db record(s)
  def self.destroy(essence)
    begin
      Nabu::Catalog.instance.delete_essence(essence)
    rescue StandardError => e
      return { error: "Essence removed, but deleting file failed: #{e.message}" }
    end

    Rails.logger.info "[DELETE] Removed essence file at [#{essence.item.full_identifier}:#{essence.filename}"

    essence.destroy

    { notice: 'Essence removed successfully, and file deleted from archive (undo not possible).' }
  end
end
