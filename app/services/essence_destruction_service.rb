class EssenceDestructionService
  def self.destroy(essence)
    result = false
    begin
      FileUtils.rm(essence.path)
      result = true
    rescue => e
      # do some basic cleanup on the error output to make it more user friendly
      output = e.message.sub(/@ unlink.*? /,'')
    end
    essence.destroy
    if result
      {notice: 'Essence removed successfully, also from archive (undo not possible).'}
    else
      {error: "Essence removed, but file removing had error: #{output}"}
    end
  end
end