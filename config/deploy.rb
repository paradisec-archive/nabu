# config valid for current version and patch releases of Capistrano
lock "~> 3.17.1"

set :application, "nabu"
set :repo_url, "git@github.com:nabu-catalog/nabu"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, -> { "/srv/www/#{fetch :application}" }

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor", "storage"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# Ruby
set :rbenv_ruby, '3.1.3'

# puma
set :puma_systemctl_user, fetch(:user)
set :puma_enable_socket_service, true
set :puma_bind, "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"

# Rails
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'tmp/locks'

# dotenv
append :linked_files, '.env'

namespace :sunspot do
  task :reindex do
    on roles(:app) do
      within release_path do
        execute :pwd
        execute :bundle, :exec, :rake, 'sunspot:reindex', "RAILS_ENV=#{fetch :rails_env}"
      end
    end
  end
end

namespace :viewer do
  desc 'Create a symlink to the viewer'
  task :create_symlink do
    on roles(:app) do
      execute "ln -s /srv/www/viewer/current #{release_path}/public/viewer"
    end
  end
end

after 'deploy:publishing', 'viewer:create_symlink'

# Sentry
set :sentry_api_token, ENV['SENTRY_API_TOKEN']
set :sentry_organization, 'nabu-d0'
