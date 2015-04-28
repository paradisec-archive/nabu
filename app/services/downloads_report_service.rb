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

    "SELECT Downloads.created_at,
        Users.country,
        Collections.title AS collection_title,
        Essences.filename,
        Items.title AS item_title
      FROM Downloads
        INNER JOIN Essences ON
        Downloads.essence_id = Essences.id
        INNER JOIN Items ON
        Essences.item_id = Items.id
        INNER JOIN Collections ON
        Items.collection_id = Collections.id
        INNER JOIN Users ON
        Downloads.user_id = Users.id
      WHERE Items.collector_id = #{@user.id}
      AND Downloads.created_at BETWEEN '#{active_date_from.strftime('%Y-%m-%d %H:%M:%S')}' AND '#{active_date_to.strftime('%Y-%m-%d %H:%M:%S')}'
     "
  end
end
