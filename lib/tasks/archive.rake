require 'nabu/media'

include ActionView::Helpers::NumberHelper
require "#{Rails.root}/app/helpers/application_helper"
include ApplicationHelper

# Coding style for log messages:
# # Only use SUCCESS if an entire action has been completed successfully, not part of the action
# # Use INFO for progress through part of an action
# # ERROR has its usual meaning
# # No need for a keyword for announcing a particular action is about to start,
# # or has just finished

# TODO: Temp till new ingest system

archive_dir = '/srv/catalog'

namespace :archive do
  desc 'Import files into the archive'
  task :import_files => :environment do
    verbose = ENV['VERBOSE'] ? true : false
    dry_run = ENV['DRY_RUN'] ? true : false

    # Always update metadata, unlike the update_files task
    force_update = true

    # find essence files in Nabu::Application.config.upload_directories
    dir_list = Nabu::Application.config.upload_directories

    dir_list.each do |upload_directory|
      puts 'Start processing files to import...'
      files_array.each do |file|
        puts '---------------------------------------------------------------'

        # Action: If it's PDSC_ADMIN, move the file
        # Action: If it fails to import, move to rejected.
        # files of the pattern "#{collection_id}-#{item_id}-xxx-PDSC_ADMIN.xxx"
        # will be copied, but not added to the list of imported files in Nabu.
        if is_non_admin_file && success
          # extract media metadata from file
          puts "INFO: Inspecting file #{file}..."
          begin
            if dry_run
              puts "DRY_RUN: file #{file} would be imported into Nabu"
            else
              success = import_metadata(upload_directory, file, item, extension, force_update)
            end
          rescue => e
            puts "ERROR: file #{file} skipped - error importing metadata [#{e.message}]" if verbose
            puts " >> #{e.backtrace}"
            success = false
          end
        end


        # Try doing generation of thumbnails. Failure to do this does not indicate a failure of the import process,
        # so don't worry about success value.
        # REVIEW: Can this code throw an exception?
        if success
          full_file_path = destination_path + "/" + file
          essence = Essence.where(:item_id => item, :filename => file).first
          media = Nabu::Media.new full_file_path
          if dry_run
            puts "DRY_RUN: thumbnails for file #{file} would be generated"
          else
            generate_derived_files(full_file_path, item, essence, extension, media, verbose)
          end
        end

        puts "...done"
      end
    end
  end

  desc 'Provide essence files in scan_directory with metadata for sealing'
  task :export_metadata => :environment do
    verbose = ENV['VERBOSE'] ? true : false
    dry_run = ENV['DRY_RUN'] ? true : false

    warden = Warden::Proxy.new({}, Warden::Manager.new({})).tap{|i| i.set_user(User.admins.first, scope: :user) }
    item_renderer = ItemsController.renderer.new('warden' => warden)

    # scan for WAV files .wav and create .imp.xml & id3.xml
    dir_contents = Dir.entries(Nabu::Application.config.scan_directory)

    # for each essence file, find its collection & item
    # by matching the pattern
    # "#{collection_id}-#{item_id}-xxx.xxx"
    dir_contents.each do |file|
      # To move to rejected, have success false
      # To leave alone, skip an iteration of this loop with next, or have success true
      success = true

      # Action: Leave as-is.
      unless File.file? "#{Nabu::Application.config.scan_directory}/#{file}"
        next
      end
      basename, _, coll_id, item_id, collection, item = parse_file_name(file, 'wav')
      # Action: Move to rejected folder.
      if !collection || !item
        # No need to log a failure message, as parse_file_name does that.
        success = false
      end

      if basename.nil?
        # Action: Move to rejected folder
        puts "ERROR: failed to determine basename for file #{file} - skipping" if verbose
        success = false
      else
        # Action: Leave as-is.
        # if metadata files exist, skip to the next file
        metadata_filename_imp = Nabu::Application.config.write_imp + basename + ".imp.xml"
        metadata_filename_id3 = Nabu::Application.config.write_id3 + basename + ".id3.v2_3.xml"
        if (File.file? "#{metadata_filename_imp}") && (File.file? "#{metadata_filename_id3}")
          next
        end
      end

      # Action: Move to rejected folder.
      # check if the item's "metadata ready for export" flag is set
      # raise a warning if not and skip file
      if success && !item.metadata_exportable
        puts "ERROR: metadata of item pid=#{coll_id}-#{item_id} is not complete for file #{file} - skipping" if verbose
        success = false
      end

      if success
        data_imp = item_renderer.render("items/show_imp", :formats => [:xml], :assigns => { :item => item })
        data_id3 = item_renderer.render("items/show_id3", :formats => [:xml], :assigns => { :item => item })

        if dry_run
          puts "DRY_RUN: metadata files\n #{metadata_filename_imp},\n #{metadata_filename_id3}\n would be created for #{file}"
        else
          File.open(metadata_filename_imp, 'w') {|f| f.write(data_imp)}
          File.open(metadata_filename_id3, 'w') {|f| f.write(data_id3)}
          puts "SUCCESS: metadata files\n #{metadata_filename_imp},\n #{metadata_filename_id3}\n created for #{file}"
        end
      else
        rejected_directory = Nabu::Application.config.scan_directory + "Rejected/"
        unless File.directory?(rejected_directory)
          puts "ERROR: file #{file} not rejected - Rejected file folder #{rejected_directory} does not exist" if verbose
          next
        end

        begin
          if dry_run
            puts "DRY_RUN: file #{file} would be copied into rejected file folder at #{rejected_directory}"
          else
            FileUtils.cp(Nabu::Application.config.scan_directory + file, rejected_directory + file)
          end
        rescue
          puts "ERROR: file #{file} skipped - not able to read it or write to #{rejected_directory + file}" if verbose
          next
        end

        puts "INFO: file #{file} copied into rejected file folder at #{rejected_directory}"
        # Only delete in the failure scenario, not in the success scenario
        if dry_run
          puts "DRY_RUN: file #{file} would be deleted from #{Nabu::Application.config.scan_directory}"
        else
          FileUtils.rm(Nabu::Application.config.scan_directory + file)
        end
      end
    end
  end



  desc 'Create all missing PDSC_ADMIN files'
  task admin_files: :environment do
    verbose = ENV['VERBOSE'] ? true : false
    dry_run = ENV['DRY_RUN'] ? true : false

    AdminFilesService.run(verbose, archive_dir, dry_run)
  end

  desc "Mint DOIs for objects that don't have one"
  task mint_dois: :environment do
    dry_run = ENV['DRY_RUN'] ? true : false
    batch_size = Integer(ENV['MINT_DOIS_BATCH_SIZE'] || 100)
    BatchDoiMintingService.run(batch_size, dry_run)
  end

  desc 'Perform image transformations for all image essences'
  task transform_images: :environment do
    batch_size = Integer(ENV['IMAGE_TRANSFORMER_BATCH_SIZE'] || 100)
    dry_run = ENV['DRY_RUN'] ? true : false
    verbose = ENV['VERBOSE'] ? true : false
    BatchImageTransformerService.run(batch_size, verbose, dry_run)
  end

  desc 'Update catalog details of items'
  task update_item_catalogs: :environment do
    dry_run = ENV['DRY_RUN'] ? true : false
    offline_template = OfflineTemplate.new
    BatchItemCatalogService.run(offline_template, dry_run)
  end

  desc 'Transcode essence files into required formats'
  task transcode_essence_files: :environment do
    dry_run = ENV['DRY_RUN'] ? true : false
    batch_size = Integer(ENV['TRANSCODE_ESSENCE_FILES_BATCH_SIZE'] || 100)
    BatchTranscodeEssenceFileService.run(batch_size, dry_run)
  end

  # HELPERS
  def parse_file_name(file, file_extension=nil)
    verbose = ENV['VERBOSE'] ? true : false

    extension = file.split('.').last
    return if file_extension && file_extension != extension
    basename = File.basename(file, "." + extension)

    #use basename to avoid having item_id contain the extension
    coll_id, item_id, *remainder = basename.split('-')
    unless item_id
      puts "ERROR: could not parse collection id and item id for file #{file} - skipping" if verbose
      return [basename, extension, coll_id, item_id, nil, nil]
    end

    # force case sensitivity in MySQL - see https://dev.mysql.com/doc/refman/5.7/en/case-sensitivity.html
    collection = Collection.where('BINARY identifier = ?', coll_id).first
    unless collection
      # Nabu Import Messages 6.
      # Action: Move to rejected folder.
      puts "ERROR: could not find collection id=#{coll_id} for file #{file} - skipping" if verbose
      return [basename, extension, coll_id, item_id, nil, nil]
    end

    # force case sensitivity in MySQL - see https://dev.mysql.com/doc/refman/5.7/en/case-sensitivity.html
    item = collection.items.where('BINARY identifier = ?', item_id).first
    unless item
      # Nabu Import Message 7.
      # Action: Move to rejected folder.
      puts "ERROR: could not find item pid=#{coll_id}-#{item_id} for file #{file} - skipping" if verbose
      return [basename, extension, coll_id, item_id, nil, nil]
    end

    is_correctly_named_file = remainder.count == 1 && remainder.none?(&:empty?)
    is_admin_file = %w(CAT df PDSC_ADMIN).include?(remainder.last)

    # don't allow too few or too many dashes
    unless is_correctly_named_file || is_admin_file
      puts "ERROR: invalid filename for file #{file} - skipping" if verbose
      return [basename, extension, coll_id, item_id, nil, nil]
    end

    [basename, extension, coll_id, item_id, collection, item]
  end


  def import_metadata(path, file, item, extension, force_update)
    essence.fps        = media.fps

    essence.save!
  end

  # this method tries to avoid regenerating any files that already exist
  def generate_derived_files(full_file_path, item, essence, extension, media, verbose)
    ImageTransformerService.new(media, full_file_path, item, essence, ".#{extension}", verbose).perform_conversions
  end
end
