namespace :catalog do
  desc 'Backfill extracted text for essences missing it. Optional: EXTENSIONS=pdf,docx,xml ESSENCE_ID=123'
  task backfill_extracted_text: :environment do
    all_extensions = %w[pdf eaf csv docx xlsx odt rtf srt txt textgrid xml imdi cmdi opex flextext]
    extensions = ENV.fetch('EXTENSIONS', all_extensions.join(',')).split(',').map(&:strip)

    invalid = extensions - all_extensions
    abort "Unknown extensions: #{invalid.join(', ')}. Valid: #{all_extensions.join(', ')}" if invalid.any?

    lambda_client = Aws::Lambda::Client.new(region: 'ap-southeast-2')
    function_name = ENV.fetch('BACKFILL_LAMBDA', "paragest-backfill-extract-text-#{Rails.env.production? ? 'prod' : 'stage'}")

    essences = if ENV['ESSENCE_ID']
                 Essence.where(id: ENV['ESSENCE_ID']).includes(item: :collection)
               else
                 extension_conditions = extensions.map { |ext| Essence.arel_table[:filename].matches("%.#{ext}") }.reduce(:or)
                 Essence.where(extracted_text: nil).where(extension_conditions).includes(item: :collection)
               end

    total = essences.count
    puts "Found #{total} essences to backfill (extensions: #{extensions.join(', ')})"

    succeeded = Concurrent::AtomicFixnum.new(0)
    failed = Concurrent::AtomicFixnum.new(0)
    processed = Concurrent::AtomicFixnum.new(0)
    pool = Concurrent::FixedThreadPool.new(5)

    essences.find_each.each_slice(5) do |slice|
      futures = slice.map do |essence|
        Concurrent::Promises.future_on(pool) do
          s3_key = essence.full_identifier
          extension = File.extname(essence.filename).delete_prefix('.')

          payload = {
            essenceId: essence.id.to_s,
            s3Key: s3_key,
            extension: extension,
            mimetype: essence.mimetype,
            size: essence.size
          }

          response = lambda_client.invoke(
            function_name: function_name,
            invocation_type: 'RequestResponse',
            payload: JSON.dump(payload)
          )

          result = JSON.parse(response.payload.read)
          index = processed.increment
          if response.function_error.nil?
            succeeded.increment
            puts "[#{index}/#{total}] #{s3_key}: #{result['characters']} chars"
          else
            failed.increment
            puts "[#{index}/#{total}] #{s3_key}: FAILED - #{result['errorMessage']}"
          end
        rescue StandardError => e
          index = processed.increment
          failed.increment
          puts "[#{index}/#{total}] #{essence.full_identifier}: ERROR - #{e.message}"
        end
      end

      futures.each(&:value!)
    end

    pool.shutdown
    pool.wait_for_termination

    puts "\nDone. #{succeeded.value} succeeded, #{failed.value} failed out of #{total}"
  end
end
