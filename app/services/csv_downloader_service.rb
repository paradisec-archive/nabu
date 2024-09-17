require 'zip'

class CsvDownloaderService
  INCLUDED_CSV_FIELDS = %i[full_identifier title external description url collector_sortname operator_name csv_item_agents
                           csv_filenames csv_mimetypes csv_fps_values csv_samplerates csv_channel_counts
                           university_name language dialect csv_subject_languages csv_content_languages csv_countries region csv_data_categories csv_data_types
                           discourse_type_name originated_on originated_on_narrative north_limit south_limit west_limit east_limit access_condition_name
                           access_narrative].freeze

  CSV_OPTIONS = { quote_char: '"', col_sep: ',', row_sep: "\n", headers: INCLUDED_CSV_FIELDS.map { |f| f.to_s.titleize }, write_headers: true }.freeze

  include HasSearch
  self.search_model = Item

  def initialize(search_type, params, current_user)
    @search_type = search_type
    @params = params
    @current_user = current_user
    @csv_requested_time = DateTime.now
  end

  attr_reader :params, :current_user

  def create_csv(search, csv)
    search.each { |r| csv << INCLUDED_CSV_FIELDS.map { |f| r.public_send(f) } }

    # if the user requested all results, iterate over the remaining pages
    while @params[:export_all] && search.next_page
      @params.merge!(page: search.next_page)
      search = @search_type == :basic ? build_basic_search : build_advanced_search
      search.each { |r| csv << INCLUDED_CSV_FIELDS.map { |f| r.public_send(f) } }
    end
  end

  def email
    return unless @current_user.email.present?

    generation_start = DateTime.now
    search = @search_type == :basic ? build_basic_search : build_advanced_search

    Rails.logger.info { "#{generation_start} Generating CSV for download" }

    path = Rails.root.join('tmp', "nabu_items_#{Time.zone.today}.csv").to_s

    CSV.open(path, 'wb', **CSV_OPTIONS) do |csv|
      create_csv(search, csv)
    end

    total = @params[:export_all] ? search.total_count : (@params[:per_page] || 10)

    generation_end = DateTime.now
    Rails.logger.info { "#{generation_end} CSV generation completed after #{generation_end.to_i - generation_start.to_i} seconds" }

    filename = "nabu_items_#{Time.zone.today}.zip"
    zip_path = Rails.root.join('tmp', filename).to_s

    Zip::File.open(zip_path, create: true) do |zipfile|
      zipfile.add(File.basename(path), path)
    end

    CsvDownloadMailer.csv_download_email(
      @current_user.email,
      # default just first name, but fall back to last in case of only one name
      @current_user.first_name || @current_user.last_name,
      total,
      @csv_requested_time.in_time_zone('Australia/Sydney'),
      filename,
      zip_path
    ).deliver_now

    File.delete(path)
  end

  def stream(search)
    filename = "nabu_items_#{Time.zone.today}.csv"

    # use enumerator to customise streaming the response
    streamed_csv = lambda { |output|
      csv = CSV.new(output, **CSV_OPTIONS)
      create_csv(search, csv)
    }

    [filename, streamed_csv]
  end
end
