class LanguageRefreshService
  STAGES = [LanguageRefresh::IsoStage, LanguageRefresh::GlottologStage, LanguageRefresh::AustlangStage].freeze
  SHRINK_LIMIT = 0.05
  LOCK_NAME = 'nabu_language_refresh'.freeze

  def initialize(fetcher: LanguageRefresh::Fetcher.new, stages: STAGES)
    @fetcher = fetcher
    @stages = stages
  end

  def run
    with_lock do
      run = LanguageRefreshRun.create!(started_at: Time.current)

      begin
        @stages.each { |stage_class| run_stage(run, stage_class.new(@fetcher)) }
        run.update!(report: LanguageRefresh::Report.new(run).body)
        LanguageRefreshMailer.with(run:).report.deliver_now
        run.update!(status: :completed, finished_at: Time.current)
      rescue StandardError
        run.update!(status: :failed, finished_at: Time.current)
        raise
      end

      run
    end
  end

  private

  # A MySQL named lock belongs to the session, so a Run that dies releases it with its connection.
  def with_lock
    ActiveRecord::Base.with_connection do |connection|
      unless connection.get_advisory_lock(LOCK_NAME)
        Rails.logger.warn('Language Refresh skipped: another Run holds the lock')
        return
      end

      begin
        yield
      ensure
        connection.release_advisory_lock(LOCK_NAME)
      end
    end
  end

  def run_stage(run, stage)
    entry = { 'started_at' => Time.current }

    stage.fetch
    entry.merge!('version' => stage.version, 'rows' => stage.row_count)

    shrinkage = shrinkage(run, stage)
    return entry.merge!('status' => 'refused', 'error' => shrinkage) if shrinkage

    result = PaperTrail.request(enabled: false) { Language.transaction(requires_new: true) { stage.apply(run) } }
    reindex(result.delete(:reindex))
    entry.merge!('status' => 'applied', **result.deep_stringify_keys)
  rescue StandardError => e
    Sentry.capture_exception(e, extra: { language_refresh_run: run.id, source: stage.source })
    Rails.logger.error("Language Refresh #{stage.source} failed: #{e.class}: #{e.message}")
    entry.merge!('status' => 'failed', 'error' => e.message)
  ensure
    run.record_source(stage.source, entry.merge('finished_at' => Time.current))
  end

  # Rewriting a join table moves tags no Language callback sees, so the Refresh reindexes the
  # Languages the tags landed on once the stage's transaction has committed.
  def reindex(language_ids)
    Language.where(id: language_ids).find_each { |language| LanguageReindexJob.perform_later(language) }
  end

  # A download that lost rows looks exactly like a mass retirement, so a big enough drop is refused.
  def shrinkage(run, stage)
    previous = run.previous_rows(stage.source)
    return if previous.nil? || previous.zero?

    drop = (previous - stage.row_count).fdiv(previous)
    return if drop <= SHRINK_LIMIT

    "#{stage.row_count} rows is #{(drop * 100).round(1)}% fewer than the #{previous} the last applied Run read"
  end
end
