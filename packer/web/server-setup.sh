#!/bin/bash

# Update the system and install necessary packages
sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git-core zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison curl sqlite-devel

# Install rbenv
cd
git clone git://github.com/sstephenson/rbenv.git .rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Install ruby-build
git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bash_profile
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
eval "$(rbenv init -)"

# Install updated ruby
rbenv install -v 2.4.1
rbenv global 2.4.1

# Don't install local documentation for gems
echo "gem: --no-document" > ~/.gemrc
gem install bundler
rbenv rehash

# Install Javascript runtime
git clone https://github.com/creationix/nvm.git .nvm
cd ~/.nvm
git checkout v0.33.6
. nvm.sh
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bash_profile
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bash_profile
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.bash_profile
nvm install node
# Symlink node so Rails app gems can find it properly
sudo ln -s ~/.nvm/versions/node/$(node -v)/bin/node /usr/bin/node

# Install Nginx
sudo yum install -y nginx
# Remove the default nginx.conf, it will be replaced by a file provisioner
sudo rm /etc/nginx/nginx.conf
sudo chkconfig nginx on

# Install Monit
sudo yum install -y monit
sudo chkconfig monit on

# Install Postgres libs
sudo yum install -y postgresql-libs postgresql-devel

########################################################################
# Setup app directory
sudo mkdir -p /data0/hydra
sudo chown -R ec2-user:ec2-user /data0/hydra

# Clone OD2 into place
cd /data0/hydra
mkdir -p shared/config
mkdir -p shared/tmp/puma
mkdir -p shared/tmp/nginx/client_temp
mkdir -p shared/sockets
mkdir -p shared/log

git clone https://github.com/OregonDigital/OD2.git current
cd current
bundle install
rm -rf tmp && ln -s /data0/hydra/shared/tmp tmp
rm -rf log && ln -s /data0/hydra/shared/log log
ln -s /data0/hydra/shared/config/local_env.yml /data0/hydra/current/config/local_env.yml
