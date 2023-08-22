class EssenceDestructionService

  # remove file and db record(s)
  def self.destroy(essence)
    result = false

    begin
      FileUtils.rm_f(essence.path)

      Rails.logger.info "[DELETE] Removed essence file at [#{essence.path}]"

      admin_files_regex = essence.path.sub(/\..+?$/, '*PDSC_ADMIN*')
      FileUtils.rm_f Dir.glob(admin_files_regex)

      Rails.logger.info "[DELETE] Removed any admin files for essence at [#{admin_files_regex}]"

      result = true
    rescue => e
      # do some basic cleanup on the error output to make it a little more user friendly
      output = e.message.sub(/@ unlink.*? /,'')
    end

    essence.destroy

    if result
      { notice: 'Essence removed successfully, and file deleted from archive (undo not possible).' }
    else
      { error: "Essence removed, but deleting file failed with error: #{output}" }
    end
  end

end
