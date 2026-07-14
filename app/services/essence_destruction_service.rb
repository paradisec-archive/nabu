class EssenceDestructionService
  # remove the db record and schedule deletion of the file from the archive
  def self.destroy(essence)
    key = Nabu::Catalog.instance.essence_key(essence)

    unless essence.destroy
      reasons = essence.errors.full_messages.join(', ')
      Rails.logger.error "[DELETE] Failed to destroy essence [#{essence.item.full_identifier}:#{essence.filename}]: #{reasons}"

      return { error: "Essence could not be removed: #{reasons}" }
    end

    DeleteCatalogFilesJob.perform_later([key])

    Rails.logger.info "[DELETE] Scheduled file deletion for essence [#{essence.item.full_identifier}:#{essence.filename}]"

    { notice: 'Essence removed; file deletion from the archive has been scheduled (undo not possible).' }
  end
end
