namespace :essence_annotations do
  desc 'Backfill EssenceAnnotation rows from the legacy basename-matching inference (eaf <-> media)'
  task backfill: :environment do
    legacy_target_exts = %w[mp3 ogg oga wav mp4 webm ogv mov].freeze
    batch_rows = []
    flush_size = 1000
    inserted = 0
    skipped = 0
    before_count = EssenceAnnotation.count

    existing_pairs = Set.new
    EssenceAnnotation.in_batches(of: 5000).each_record do |row|
      existing_pairs.add([row.annotation_essence_id, row.target_essence_id])
    end

    flush = lambda do
      next if batch_rows.empty?

      EssenceAnnotation.insert_all(batch_rows)
      inserted += batch_rows.size
      batch_rows.clear
    end

    Item.includes(:essences).find_in_batches(batch_size: 500) do |items|
      items.each do |item|
        eafs = []
        media_by_basename = Hash.new { |h, k| h[k] = [] }

        item.essences.each do |essence|
          ext = File.extname(essence.filename).delete('.').downcase
          basename = File.basename(essence.filename, File.extname(essence.filename))

          if ext == 'eaf'
            eafs << [basename, essence]
          elsif legacy_target_exts.include?(ext)
            media_by_basename[basename] << essence
          end
        end

        now = Time.current
        eafs.each do |basename, eaf|
          media_by_basename[basename].each do |media|
            pair = [eaf.id, media.id]
            if existing_pairs.include?(pair)
              skipped += 1
              next
            end

            existing_pairs.add(pair)
            batch_rows << {
              annotation_essence_id: eaf.id,
              target_essence_id: media.id,
              created_at: now,
              updated_at: now
            }
          end
        end

        flush.call if batch_rows.size >= flush_size
      end
    end

    flush.call

    after_count = EssenceAnnotation.count
    puts 'Backfill complete:'
    puts "  EssenceAnnotation rows before: #{before_count}"
    puts "  EssenceAnnotation rows after:  #{after_count}"
    puts "  Newly inserted: #{inserted}"
    puts "  Skipped (already existed): #{skipped}"
  end
end
