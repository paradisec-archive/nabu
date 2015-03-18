class EssenceDestructionService
  def self.destroy(essence)
    output = %x{rm #{essence.path} 2>&1}
    result = $?
    essence.destroy
    if result.success?
      {notice: "Essence removed successfully, also from archive (undo not possible)."}
    else
      {error: "Essence removed, but file removing had error: #{output}"}
    end
  end
end