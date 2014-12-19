# How to set up a server for the app

# Add a user for yourself

    adduser johnf
    adduser johnf admin

# Create a deploy user

    adduser --shell /bin/bash --gecos Deploy --disabled-password deploy

# Add ssh keys

    mkdir -p ~johnf/.ssh
    mkdir -p ~deploy/.ssh
    vi ~johnf/.ssh/authorized_keys
    cp ~johnf/.ssh/authorized_keys ~deploy/.ssh
    chown johnf.johnf -R ~johnf
    chown deploy.deploy -R ~deploy

# Disable SSH Root Login
    vi /etc/ssh/sshd_config
    # PermitRootLogin no
    service ssh restart

# Cleanup

    sudo aptitude purge nano consolekit
    sudo deluser --remove-home ubuntu
    sudo visudo
    # Remove the ubuntu entry
    deborphan -a
    # Remove unneeded packages
    sudo aptitude purge ubuntu-serverguide wpasupplicant landscape-client wireless-tools libnl1 libiw30

# Basic Setup
    sudo dpkg-reconfigure tzdata
    sudo locale-gen en_AU en_AU.UTF-8
    sudo vi /etc/default/rcS
    sudo vi /etc/apt/sources.list
    sudo apt-get update
    sudo apt-get dist-upgrade
    sudo apt-get install vim deborphan htop mailutils tcpdump ngrep git-core postfix

# Percona Server
    echo "deb http://repo.percona.com/apt precise main" | sudo tee /etc/apt/sources.list.d/percona.list
    sudo /usr/bin/apt-key adv --recv-keys --keyserver keys.gnupg.net 1C4CBDCDCD2EFD2A
    sudo apt-get update
    sudo aptitude install percona-server-client percona-server-server percona-toolkit percona-xtrabackup
    # Generate a mysql config
    https://tools.percona.com/configuration/P2SAITsO
    mysql -u root
        CREATE DATABASE nabu;

# Nginx

    sudo apt-get install nginx-full
    sudo rm /etc/nginx/sites-enabled/default
    sudo mkdir /srv/www
    sudo mkdir /srv/www/nabu
    sudo chown -R deploy.deploy /srv/www/nabu
    vi /etc/nginx/sites-enabled/nabu
        upstream nabu_prod_pool {
        server unix:/srv/www/nabu/shared/sockets/unicorn.sock;
        fair;
        }

        server {
        listen                  80;
        server_name             _;
        server_name_in_redirect off;
        server_tokens           off;

        root /srv/www/nabu/current/public;

        location / {
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Host $http_host;
            proxy_redirect off;

            client_max_body_size 50m;

            # If you don't find the filename in the static files
            # Then request it from the unicorn server
            if (!-f $request_filename) {
            proxy_pass http://nabu_prod_pool;
            break;
            }

            error_page 500 502 503 504 /500.html;
            location = /500.html {
            root /srv/www/nabu/current/public;
            }
        }

# Ruby

    /usr/bin/git clone git://github.com/sstephenson/rbenv /opt/rbenv
    mkdir /opt/rbenv/plugins
    sudo vi /etc/profile.d/rbenv.sh
        # Add rbenv tools to path
        export PATH="/opt/rbenv/bin:$PATH"
        export RBENV_ROOT="/opt/rbenv"
        eval "$(rbenv init -)"
    /usr/bin/git clone git://github.com/sstephenson/ruby-build.git /opt/rbenv/plugins/ruby-build
    sudo apt-get install zlib1g-dev libmysqlclient-dev libxml2-dev libxslt1-dev libssl-dev g++ libreadline-dev build-essential libmagic-dev
    sudo -i
    rbenv install 1.9.3-p194
    rbenv global 1.9.3-p194
    gem install bundler
    rbenv rehash


# Java

    sudo apt-get install openjdk-6-jre-headless

# monit

http://railscasts.com/episodes/375-monit


# media processing

    sudo apt-get install libav-tools
