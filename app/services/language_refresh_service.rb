class LanguageRefreshService
  STAGES = [LanguageRefresh::IsoStage].freeze
  SHRINK_LIMIT = 0.05
  LOCK_NAME = 'nabu_language_refresh'.freeze

  def initialize(fetcher: LanguageRefresh::Fetcher.new)
    @fetcher = fetcher
  end

  def run
    with_lock do
      run = LanguageRefreshRun.create!(started_at: Time.current)
      STAGES.each { |stage_class| run_stage(run, stage_class.new(@fetcher)) }
      run.update!(status: :completed, finished_at: Time.current)
      run.update!(report: LanguageRefresh::Report.new(run).body)
      LanguageRefreshMailer.with(run:).report.deliver_now
      run
    end
  end

  private

  # A MySQL named lock belongs to the session, so a Run that dies releases it with its connection.
  def with_lock
    ActiveRecord::Base.with_connection do |connection|
      lock = connection.quote(LOCK_NAME)

      unless connection.select_value("SELECT GET_LOCK(#{lock}, 0)") == 1
        Rails.logger.warn('Language Refresh skipped: another Run holds the lock')
        return
      end

      begin
        yield
      ensure
        connection.select_value("SELECT RELEASE_LOCK(#{lock})")
      end
    end
  end

  # A stage that fails is recorded and reported, and never stops the stages after it.
  def run_stage(run, stage)
    entry = { 'started_at' => Time.current }

    stage.fetch
    entry.merge!('version' => stage.version, 'rows' => stage.rows)

    shrinkage = shrinkage(run, stage)
    return entry.merge!('status' => 'refused', 'error' => shrinkage) if shrinkage

    result = PaperTrail.request(enabled: false) { Language.transaction(requires_new: true) { stage.apply } }
    entry.merge!('status' => 'applied', **result.deep_stringify_keys)
  rescue StandardError => e
    Sentry.capture_exception(e, extra: { language_refresh_run: run.id, source: stage.source })
    Rails.logger.error("Language Refresh #{stage.source} failed: #{e.class}: #{e.message}")
    entry.merge!('status' => 'failed', 'error' => e.message)
  ensure
    run.record_source(stage.source, entry.merge('finished_at' => Time.current))
  end

  # A download that lost rows looks exactly like a mass retirement, so a big enough drop is refused.
  def shrinkage(run, stage)
    previous = run.previous_rows(stage.source)
    return if previous.nil? || previous.zero?

    drop = (previous - stage.rows).fdiv(previous)
    return if drop <= SHRINK_LIMIT

    "#{stage.rows} rows is #{(drop * 100).round(1)}% fewer than the #{previous} the last applied Run read"
  end
end
