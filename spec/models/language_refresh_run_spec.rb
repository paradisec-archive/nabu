require 'rails_helper'

describe LanguageRefreshRun, type: :model do
  it 'starts out running' do
    run = described_class.create!(started_at: Time.zone.now)

    expect(run).to be_running
  end

  it 'records what each source gave it' do
    run = described_class.create!(started_at: Time.zone.now)
    run.update!(sources: { 'iso639_3' => { 'version' => '2026-07-15', 'status' => 'completed', 'counts' => { 'created' => 317 } } })

    expect(run.reload.sources.dig('iso639_3', 'counts', 'created')).to eq(317)
  end

  it 'keeps the report it sent' do
    run = described_class.create!(started_at: Time.zone.now, report: 'Nothing changed this month.')

    expect(run.reload.report).to eq('Nothing changed this month.')
  end

  it 'rejects a status it has no meaning for' do
    run = described_class.new(started_at: Time.zone.now)
    run.status = 'halfway'

    expect(run).not_to be_valid
  end
end
