#!/bin/bash

action=$1
[ $# -eq 0 ] && { echo "Usage: $0 (start|stop|restart)"; exit 1; }

app_path="/data0/hydra/current"
rails_env="production"
config_file="$app_path/config/puma/$rails_env.rb"
log_file="$app_path/log/puma.log"
state_file="$app_path/tmp/puma/puma.state"
pid_file="$app_path/tmp/puma/puma.pid"

export RAILS_ENV="$rails_env"

if [ -d "$HOME/.rbenv/bin" ]; then
  PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
  eval "$(rbenv init -)"
elif [ -d "/usr/local/rbenv/bin" ]; then
  PATH="/usr/local/rbenv/bin:/usr/local/rbenv/shims:$PATH"
  eval "$(rbenv init -)"
fi

case $action in
  start)
    echo "Starting puma : $app_path on $rails_env with $config_file"
    cd $app_path && bundle exec puma -C $config_file 2>&1 >> $log_file
    ;;
  stop)
    echo "Stopping puma : $app_path on $rails_env with $state_file"
    cd $app_path && rbenv exec pumactl --state $state_file stop 2>&1 >> $log_file
    ;;
  restart)
    echo "Restarting puma : $app_path on $rails_env with $state_file"
    cd $app_path && rbenv exec pumactl --state $state_file phased-restart 2>&1 >> $log_file
    ;;
esac
