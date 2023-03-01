class CsvDownloader

  INCLUDED_CSV_FIELDS = [:full_identifier, :title, :external, :description, :url, :collector_sortname, :operator_name, :csv_item_agents,
                         :csv_filenames, :csv_mimetypes, :csv_fps_values, :csv_samplerates, :csv_channel_counts,
                         :university_name, :language, :dialect, :csv_subject_languages, :csv_content_languages, :csv_countries, :region, :csv_data_categories, :csv_data_types,
                         :discourse_type_name, :originated_on, :originated_on_narrative, :north_limit, :south_limit, :west_limit, :east_limit, :access_condition_name,
                         :access_narrative]

  CSV_OPTIONS = {quote_char: '"', col_sep: ',', row_sep: "\n", headers: INCLUDED_CSV_FIELDS.map{|f| f.to_s.titleize}, write_headers: true}

  def initialize(search_type, params, current_user)
      @search_type = search_type
      @params = params
      @current_user = current_user
      @csv_requested_time = DateTime.now
  end

  def email
    generation_start = DateTime.now
    search = if @search_type == :basic
               ItemSearchService.build_solr_search(@params, @current_user)
             else
               ItemSearchService.build_advanced_search(@params, @current_user)
             end

    Rails.logger.info {"#{generation_start} Generating CSV for download"}

    filename = "nabu_items_#{Date.today}.csv"
    path = "#{Rails.root}/tmp/#{filename}"

    CSV.open(path, 'wb', **CSV_OPTIONS) do |csv|
      search.results.each{|r| csv << INCLUDED_CSV_FIELDS.map{|f| r.public_send(f)}}
      # if the user requested all results, iterate over the remaining pages
      while @params[:export_all] && search.results.next_page
        search = if @search_type == :basic
                    ItemSearchService.build_solr_search(@params.merge(page: search.results.next_page), @current_user)
                  else
                    ItemSearchService.build_advanced_search(@params.merge(page: search.results.next_page), @current_user)
                  end
        search.results.each{|r| csv << INCLUDED_CSV_FIELDS.map{|f| r.public_send(f)}}
      end
    end

    total = @params[:export_all] ? search.total : (@params[:per_page] || 10)

    generation_end = DateTime.now
    Rails.logger.info {"#{generation_end} CSV generation completed after #{generation_end.to_i - generation_start.to_i} seconds"}

    if @current_user.email.present?
      CsvDownloadMailer.csv_download_email(
        @current_user.email,
        # default just first name, but fall back to last in case of only one name
        @current_user.first_name || @current_user.last_name,
        total,
        @csv_requested_time.in_time_zone('Australia/Sydney'),
        filename,
        path
      ).deliver
    end

  end

  def stream(orig_search)
    filename = "nabu_items_#{Date.today}.csv"

    search = orig_search

    # use enumerator to customise streaming the response
    streamed_csv = ->(output) {
      # wrap the IO output so that CSV pushes writes directly into it
      csv = CSV.new(output, **CSV_OPTIONS)
      search.results.each{|r| csv << INCLUDED_CSV_FIELDS.map{|f| r.public_send(f)}}

      # if the user requested all results, iterate over the remaining pages
      while @params[:export_all] && search.results.next_page
        search = if @search_type == :basic
          ItemSearchService.build_solr_search(@params.merge(page: search.results.next_page), @current_user)
        else
          ItemSearchService.build_advanced_search(@params.merge(page: search.results.next_page), @current_user)
        end
        search.results.each{|r| csv << INCLUDED_CSV_FIELDS.map{|f| r.public_send(f)}}
      end
    }

    return filename, streamed_csv

  end

end
