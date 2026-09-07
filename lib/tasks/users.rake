namespace :users do
  desc 'Delete unconfirmed users older than 14 days and send deletion report'
  task delete_unconfirmed: [:environment] do
     UnconfirmedUsersService.delete_old_users
  end
end
