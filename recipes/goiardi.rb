
execute 'apt-get update -y'

%w{postgresql-9.3 postgresql-client-9.3}.each do |pkg|
  package pkg
end

service 'postgresql'

execute 'create_postgres_user' do
  command 'createuser goiardi -w'
  user 'postgres'
  action :nothing
end

execute 'create_postgres_db' do
  command 'createdb goiardi -O goiardi'
  user 'postgres'
  action :nothing
end

file '/etc/postgresql/9.3/main/pg_hba.conf' do
  owner 'postgres'
  group 'postgres'
  mode 0640
  content <<EOF
local   all             postgres                                peer
local   all             all                                     peer
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
EOF
  notifies :restart, 'service[postgresql]', :immediately
  notifies :run, 'execute[create_postgres_user]', :immediately
  notifies :run, 'execute[create_postgres_db]', :immediately
end

user 'goiardi' do
  system true
end

remote_file '/usr/bin/goiardi' do
  source 'https://github.com/ctdk/goiardi/releases/download/v0.8.0/goiardi-0.8.0-linux-x86-64'
  checksum '49f93992ad15a20eea626a86a9e3dbe9d2ae1779131f81a7a492a6ad6e9acf6d'
  mode 0755
end
%w{/etc/goiardi /var/goiardi /var/goiardi/file_checksums}.each do |dir|
  directory dir do
    owner 'goiardi'
    group 'goiardi'
    mode 0755
  end
end

file '/etc/goiardi/goiardi.conf' do
  owner 'goiardi'
  group 'goiardi'
  mode 0644
  content <<EOF
ipaddress = "#{node.ipaddress}"
port = 4646
hostname = "#{node.name}"
log-file = "/tmp/goiardi.log"
syslog = false
log-level = "error"
#index-file = "/tmp/goiardi-index.bin"
#data-file = "/tmp/goiardi-data.bin"
#freeze-interval = 120
time-slew = "15m"
conf-root = "/etc/goiardi"
local-filestore-dir = "/var/goiardi/file_checksums"
use-auth = false
use-ssl = false
# ssl-cert="/path/to/goiardi/conf/cert.pem"
# ssl-key="/path/to/goiardi/conf/key.pem"
https-urls = false
disable-webui = false
log-events = true
#log-event-keep = 1000
#obj-max-size = 10485760
#json-req-max-size = 1000000
# use-unsafe-mem-store = false
# db-pool-size = 25
# max-connections = 50
use-serf = false
# serf-addr = "127.0.0.1:7373"
use-shovey = false
# sign-priv-key = "/path/to/shovey.key"
use-mysql = false
use-postgres = true
[postgresql]
  username = "goiardi"
  host = "localhost"
  port = "5432"
  dbname = "goiardi"
  sslmode = "disable"
EOF
end

execute 'scrub_sql_1' do
  command "sed -i 's/REVOKE ALL ON SCHEMA public FROM jeremy;/REVOKE ALL ON SCHEMA public FROM goiardi;/' /tmp/goiardi.sql"
  action :nothing
end

execute 'scrub_sql_2' do
  command "sed -i 's/GRANT ALL ON SCHEMA public TO jeremy;/GRANT ALL ON SCHEMA public TO goiardi;/' /tmp/goiardi.sql"
  action :nothing
end

execute 'restore_db' do
  user 'goiardi'
  command 'psql goiardi -f /tmp/goiardi.sql'
  action :nothing
end

remote_file '/tmp/goiardi.sql' do
  source 'https://raw.githubusercontent.com/ctdk/goiardi/master/sql-files/goiardi-schema-postgres.sql'
  action :create_if_missing
  notifies :run, 'execute[scrub_sql_1]', :immediately
  notifies :run, 'execute[scrub_sql_2]', :immediately
  notifies :run, 'execute[restore_db]', :immediately
end

file '/etc/init.d/goiardi' do
  owner 'goiardi'
  group 'goiardi'
  mode 0750
  content <<EOF
#!/bin/bash
### BEGIN INIT INFO
# Provides: goiardi
# Short-Description: goiardi - a chef server written in go
# Default-Start: 3 4 5
# Default-Stop: 0 1 2 6
# Required-Start:
# Required-Stop:
# Should-Start:
# Should-Stop:
# chkconfig: 2345 95 20
# description: goiardi
# processname: goiardi
### END INIT INFO

NAME="goiardi"
GOIARDI_BINARY='/usr/bin/goiardi'
GOIARDI_CONF_FILE='/etc/goiardi/goiardi.conf'
GOIARDI_USER='goiardi'

SLEEP_TIME=5
CURRENT_WAIT=0
TIMEOUT=30

start() {
  findPid
  if [ -z "$FOUND_PID" ]; then
    su $GOIARDI_USER -c "/usr/bin/env -i $GOIARDI_BINARY -c $GOIARDI_CONF_FILE &"
    if [[ $? -ne 0 ]]; then
      echo "Error starting $NAME"
      exit 1
    fi
    echo "$NAME successfully started"
  else
    echo "$NAME is already running"
  fi
}

stop() {
  findPid
  if [ -z "$FOUND_PID" ]; then
    echo "$NAME is not running, nothing to stop"
  else
    while [[ -n $FOUND_PID ]];
    do
      echo "Attempting to shutdown $NAME..."
      kill -INT $FOUND_PID
      if [[ $? -ne 0 ]]; then
        echo "Error stopping $NAME"
        exit 1
      fi
      sleep $SLEEP_TIME
      CURRENT_WAIT=$(($CURRENT_WAIT+$SLEEP_TIME))
      if [[ $CURRENT_WAIT -gt $TIMEOUT ]]; then
        echo "Timed out waiting for $NAME to stop"
        exit 1
      fi
      findPid
    done
    echo "Stopped $NAME"
  fi
}

status() {
  findPid
  if [ -z "$FOUND_PID" ]; then
    echo "$NAME is not running" ; exit 1
  else
    echo "$NAME is running : $FOUND_PID"
  fi
}

findPid() {
  FOUND_PID=`pgrep -f $GOIARDI_BINARY`
}

case "$1" in
  start)
    start
  ;;
  stop)
    stop
  ;;
  restart)
    stop
    start
  ;;
  status)
    status
  ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
esac

exit 0
EOF
end

service 'goiardi' do
  action :start
  supports(start: true, restart: true, stop: true, status: true)
end
