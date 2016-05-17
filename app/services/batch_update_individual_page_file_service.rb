# Update the individual page files, to no longer have dashes
class BatchUpdateIndividualPageFileService
  def self.run(dry_run)
    batch_update_individual_page_file_service = new(dry_run)
    batch_update_individual_page_file_service.run
  end

  def initialize(dry_run)
    @dry_run = dry_run
  end

  def run
    essences = Essence.where("filename like '%-page%'")
    essences.find_each(&method(:update_individual_page_file))
  end

  def update_individual_page_file(essence)
    old_path = essence.path
    unless essence.filename.index('-page') == essence.filename.rindex('-page')
      puts "#{essence.filename} has multiple '-page's in it - skipping"
      return
    end

    essence.filename = essence.filename.gsub('-page', 'page')
    new_path = essence.path

    unless File.exist?(old_path)
      puts "Can't find original file #{old_path} - skipping"
      return
    end

    if File.exist?(new_path)
      puts "File #{new_path} already exists - skipping"
      return
    end

    unless essence.valid?
      puts "#{essence.filename} not valid - skipping"
      return
    end

    unless @dry_run
      FileUtils.mv(old_path, new_path)
      essence.save!
    end
    puts "SUCCESS: #{old_path} moved to #{new_path}"
  end
end
