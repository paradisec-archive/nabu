require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
# Solid Queue only validates recurring tasks when the supervisor boots, so a renamed job or a bad
# schedule would otherwise surface in production rather than in CI.
describe 'config/recurring.yml' do
  let(:tasks) { Rails.application.config_for(:recurring, env: 'production') }

  it 'declares at least one production task' do
    expect(tasks).not_to be_empty
  end

  it 'gives every task either a class or a command' do
    expect(tasks.values).to all(include(:class).or(include(:command)))
  end

  it 'resolves every class-based task to an Active Job' do
    tasks.values.filter_map { |options| options[:class] }.each do |name|
      job_class = name.safe_constantize

      expect(job_class).to be_present, "#{name} does not resolve to a class"
      expect(job_class).to be < ActiveJob::Base
    end
  end

  it 'parses every schedule as a cron' do
    schedules = tasks.values.map { |options| Fugit.parse(options[:schedule], multi: :fail) }

    expect(schedules).to all(be_a(Fugit::Cron))
  end
end
# rubocop:enable RSpec/DescribeClass
