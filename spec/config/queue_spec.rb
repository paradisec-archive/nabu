require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
# A worker on '*' would let a multi-hour maintenance job take a thread from user-facing work.
describe 'config/queue.yml' do
  let(:workers) { Rails.application.config_for(:queue, env: 'production')[:workers] }

  it 'gives the default queue a three-thread worker' do
    expect(workers).to include(a_hash_including(queues: 'default', threads: 3))
  end

  it 'gives the maintenance queue a single-threaded worker' do
    expect(workers).to include(a_hash_including(queues: 'maintenance', threads: 1))
  end

  it 'has no worker listening on every queue' do
    expect(workers.map { |worker| worker[:queues] }).not_to include('*')
  end

  # Without the '*' worker, a queue nobody listens on silently strands its jobs. A recurring task
  # with no queue of its own falls back to its job class, and a command task to SolidQueue's own.
  it 'serves every queue the app can enqueue to' do
    Rails.application.eager_load!
    recurring = Rails.application.config_for(:recurring, env: 'production').each_value.map do |task|
      task[:queue] || (task[:class] ? task[:class].constantize : SolidQueue::RecurringJob).new.queue_name
    end
    enqueueable = ApplicationJob.descendants.map { |job| job.new.queue_name } + [ActiveJob::Base.new.queue_name] + recurring

    expect(enqueueable.uniq).to all(be_in(workers.map { |worker| worker[:queues] }))
  end
end
# rubocop:enable RSpec/DescribeClass
