namespace :users do
  desc 'Send pre-deletion report for unconfirmed users'
  task list_deletion_candidates: [:environment] do
    UnconfirmedUsersService.deletion_report
  end

  desc 'Delete unconfirmed users older than 14 days and send deletion report'
  task delete_unconfirmed: [:environment] do
     UnconfirmedUsersService.delete_old_users
  end
end
