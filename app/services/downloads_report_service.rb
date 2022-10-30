class DownloadsReportService
  def initialize(date_from, date_to, user)
    @date_from = transform_date(date_from) || (Date.today - 1.year)
    @date_to = transform_date(date_to) || Date.today
    @user = user
  end

  def send_report
    @results = ActiveRecord::Base.connection.select_all(query_sql)

    if @results.any?
      DownloadsReportMailer.downloads_email(@user, @results, @date_from, @date_to).deliver

      @results.count
    else
      0
    end
  end

  private

  def transform_date(date_string)
    if date_string.present?
      Date.parse(date_string)
    else
      nil
    end
  end

  def query_sql
    active_date_from = @date_from - 1.day
    active_date_to = @date_to + 1.day

    "SELECT downloads.created_at,
        users.country,
        collections.title AS collection_title,
        essences.filename,
        items.title AS item_title
      FROM downloads
        INNER JOIN essences ON
          downloads.essence_id = essences.id
        INNER JOIN items ON
          essences.item_id = items.id
        INNER JOIN collections ON
          items.collection_id = collections.id
        INNER JOIN users ON
          downloads.user_id = users.id
      WHERE items.collector_id = #{@user.id}
      AND downloads.created_at BETWEEN '#{active_date_from.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{active_date_to.strftime('%Y-%m-%d %H:%M:%S')}'
     "
  end
end
