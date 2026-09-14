namespace :users do
  desc 'Delete unconfirmed users older than 14 days and send deletion report'
  task delete_unconfirmed: :environment do
    DeleteUnconfirmedUsersJob.perform_now
  end
end
