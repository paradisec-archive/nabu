class ItemDestructionService
  def initialize(item, destroy_essences = false)
    @item = item
    @destroy_essences = destroy_essences
  end

  def destroy
    response = {success: true, messages: {}}

    begin
      essence_destruction_errors = delete_essences if @destroy_essences

      @item.destroy
      # remove directory and PDSC_ADMIN files on disk
      delete_directory

      if @destroy_essences
        response[:messages][:notice] = 'Item and all its contents removed permanently (no undo possible)'
      else
        response[:messages][:notice] = 'Item removed successfully'
      end

      # if there were any issues deleting the essence files, show them as well
      if essence_destruction_errors.present?
        response[:messages][:error] = "Some errors occurred while removing dependent essence files:<br/>\n#{essence_destruction_errors}"
      end

    rescue ActiveRecord::DeleteRestrictionError => e
      puts e.message
      puts e.backtrace.join("\n")
      response[:messages][:error] = 'Item has content files and cannot be removed.'
      response[:success] = false
    end

    response
  end

  private

  def delete_essences
    # delete all related essences and collect up the response messages
    messages = @item.essences.collect do |ess|
      EssenceDestructionService.destroy(ess)
    end
    @item.essences = [] # force item to have no essences

    if messages.length > 10
      'More than 10 essence files reported issues.'
    else
      # only bother returning errors
      messages.collect {|msg| msg[:error]}.uniq.join("<br/>\n")
    end
  end

  def delete_directory
    return unless File.directory?(Nabu::Application.config.archive_directory)
    directory = Nabu::Application.config.archive_directory +
      "#{@item.collection.identifier}/#{@item.identifier}/"
    return unless File.directory?(directory)
    # delete all PDSC_ADMIN files
    file = directory + "#{@item.full_identifier}*-PDSC_ADMIN.*"
    FileUtils.rm_f(file)
    FileUtils.rmdir(directory)
  end

end