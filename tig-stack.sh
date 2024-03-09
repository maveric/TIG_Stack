#!/usr/bin/env bash


INFLUXDB_GRAFANA_USER="safe"
INFLUXDB_GRAFANA_PASSWORD="jidjedewTSuIw4EmqhoOo"
INFLUXDB_TOKEN="HYdrv1bCZhsvMhYOq6_wg4NGV2OI9HZch_gh57nquSdAhbjhLMUIeYnCCAoybgJrJlLXRHUnDnz2v-xR0hDt3Q=="


export NEWT_COLORS='
window=,white
border=black,white
textbox=black,white
button=black,white
'

############################################## select TIG stack option action

SELECTION=$(whiptail --title "TIG Stack Setup" --radiolist \
"TIG Stack Setup Actions                              " 20 70 10 \
"1" "Install Telegraf" OFF \
"2" "Setup Influxdb2 & Grafana" OFF \
"3" "Install Docker Engine" OFF \
"4" "Exit" ON \
"5" "Stop & Uninstall TIG Stack" OFF 3>&1 1>&2 2>&3)

if [[ $? -eq 255 ]]; then
exit 0
fi

############################################################################################################################################### Install Telegraf
if [[ "$SELECTION" == "1" ]]; then

# stop Telegraf docker if running
docker compose --project-directory $HOME/.local/share/tig-stack/telegraf down

#remove old folders and config files if they exist 
sudo rm -rf $HOME/.local/share/tig-stack/telegraf

# enter the ipaddress and port of the influx instalation
INFLUXDB_IP_PORT=$(whiptail --title "IP address & Port of Influxdb2" --inputbox "\nIP address & Port of Influxdb2" 8 40 0.0.0.0:8086 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi

# enter the token that will allow data to be writen to the influx DB
INFLUXDB_TOKEN=$(whiptail --title "Hostname for identification in Influxdb" --inputbox "\nInflux Token" 8 40 "HYdrv1bCZhsvMhYOq6_wg4NGV2OI9HZch_gh57nquSdAhbjhLMUIeYnCCAoybgJrJlLXRHUnDnz2v-xR0hDt3Q==" 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi

## enter hostname which will be used as inlux label to identify which system the telegraf data comes from
HOSTNAME=$(whiptail --title "Hostname for identification in Influxdb" --inputbox "\nHostname for identification in Influxdb" 8 40 Hostname 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi

#make Telegraf directory
mkdir -p $HOME/.local/share/tig-stack/telegraf

#create telegraf config file
tee $HOME/.local/share/tig-stack/telegraf/telegraf.conf 2>&1 > /dev/null <<EOF
# Configuration for telegraf agent
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  hostname = "$HOSTNAME"
  omit_hostname = false
  
[[outputs.influxdb_v2]]
  urls = ["http://$INFLUXDB_IP_PORT"]
  token = "$INFLUXDB_TOKEN"
  organization = "safe-org"
  bucket = "telegraf"

########################################################## Monitors CPU
[[inputs.cpu]]
  percpu = false
  totalcpu = true
  collect_cpu_time = false
  report_active = false
  core_tags = false
  
######################################################### Read metrics about memory usage
[[inputs.mem]]
  # no configuration

######################################################### Monitors internet speed using speedtest.net service
[[inputs.internet_speed]]
  ## This plugin downloads many MB of data each time it is run. As such
  ## consider setting a higher interval for this plugin to reduce the
  ## demand on your internet connection.
  interval = "10m"

  ## Sets if runs file download test
  # enable_file_download = false

  ## Caches the closest server location
  # cache = false

########################################################### Read metrics about disk usage by mount point
[[inputs.disk]]
  ## By default stats will be gathered for all mount points.
  ## Set mount_points will restrict the stats to only the specified mount points.
  # mount_points = ["/"]

  ## Ignore mount points by filesystem type.
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

  ## Ignore mount points by mount options.
  ## The 'mount' command reports options of all mounts in parathesis.
  ## Bind mounts can be ignored with the special 'bind' option.
  # ignore_mount_opts = []

EOF


# write docker compose config file

tee $HOME/.local/share/tig-stack/telegraf/docker-compose.yaml 2>&1 > /dev/null <<EOF
version: "3.8"
services:

  telegraf:
    image: telegraf:1.29.5
    container_name: telegraf
    user: "1000:1000"
    volumes:
      # Make sure you create this local directory
      - $HOME/.local/share/tig-stack/telegraf/telegraf.conf:/etc/telegraf/telegraf.conf
    restart: unless-stopped
    networks:
      - tig_network

networks:
  tig_network:
    driver: bridge
EOF


# start telegraf docker and start loging tp influx 
docker compose --project-directory $HOME/.local/share/tig-stack/telegraf/ up

############################################################################################################################################ Setup Influxdb2 & Grafana
elif [[ "$SELECTION" == "2" ]]; then

# stop Influxdb and grafana docker if running
docker compose --project-directory $HOME/.local/share/tig-stack/ down

#remove old folders and config files if they exists
sudo rm -rf $HOME/.local/share/tig-stack/grafana \
  $HOME/.local/share/tig-stack/influxdb

#make local directorys

mkdir -p $HOME/.local/share/tig-stack/influxdb/data \
  $HOME/.local/share/tig-stack/influxdb/config \
  $HOME/.local/share/tig-stack/grafana/data \
  $HOME/.local/share/tig-stack/grafana/config \
  $HOME/.local/share/tig-stack/grafana/log


#write the influxdb.conf file leave this as it is for defaults
tee $HOME/.local/share/tig-stack/influxdb/config/config.yml 2>&1 > /dev/null <<EOF
assets-path: ""
bolt-path: /var/lib/influxdb2/influxd.bolt
e2e-testing: false
engine-path: /var/lib/influxdb2/engine
feature-flags: {}
flux-log-enabled: false
hardening-enabled: false
http-bind-address: :8086
http-idle-timeout: 3m0s
http-read-header-timeout: 10s
http-read-timeout: 0s
http-write-timeout: 0s
influxql-max-select-buckets: 0
influxql-max-select-point: 0
influxql-max-select-series: 0
instance-id: ""
key-name: ""
log-level: info
metrics-disabled: false
nats-max-payload-bytes: 0
no-tasks: false
pprof-disabled: false
query-concurrency: 1024
query-initial-memory-bytes: 0
query-max-memory-bytes: 0
query-memory-bytes: 0
query-queue-size: 1024
reporting-disabled: false
secret-store: bolt
session-length: 60
session-renew-disabled: false
sqlite-path: ""
storage-cache-max-memory-size: 1073741824
storage-cache-snapshot-memory-size: 26214400
storage-cache-snapshot-write-cold-duration: 10m0s
storage-compact-full-write-cold-duration: 4h0m0s
storage-compact-throughput-burst: 50331648
storage-max-concurrent-compactions: 0
storage-max-index-log-file-size: 1048576
storage-no-validate-field-size: false
storage-retention-check-interval: 30m0s
storage-series-file-max-concurrent-snapshot-compactions: 0
storage-series-id-set-cache-size: 0
storage-shard-precreator-advance-period: 30m0s
storage-shard-precreator-check-interval: 10m0s
storage-tsm-use-madv-willneed: false
storage-validate-keys: false
storage-wal-fsync-delay: 0s
storage-wal-max-concurrent-writes: 0
storage-wal-max-write-delay: 10m0s
storage-write-timeout: 10s
store: disk
testing-always-allow-setup: false
tls-cert: ""
tls-key: ""
tls-min-version: "1.2"
tls-strict-ciphers: false
tracing-type: ""
ui-disabled: false
vault-addr: ""
vault-cacert: ""
vault-capath: ""
vault-client-cert: ""
vault-client-key: ""
vault-client-timeout: 0s
vault-max-retries: 0
vault-skip-verify: false
vault-tls-server-name: ""
vault-token: ""
EOF

# write the grafana config

tee $HOME/.local/share/tig-stack/grafana/config/custom.ini 2>&1 > /dev/null <<EOF

admin_user = $INFLUXDB_GRAFANA_USER
admin_password = $INFLUXDB_GRAFANA_PASSWORD

EOF

# write docker compose config file

tee $HOME/.local/share/tig-stack/docker-compose.yaml 2>&1 > /dev/null <<EOF
version: "3.8"
services:
  influxdb:
    image: influxdb:2.7.5
    container_name: influxdb
    environment:
      - DOCKER_INFLUXDB_INIT_MODE=setup
      - DOCKER_INFLUXDB_INIT_USERNAME=$INFLUXDB_GRAFANA_USER
      - DOCKER_INFLUXDB_INIT_PASSWORD=$INFLUXDB_GRAFANA_PASSWORD
      - DOCKER_INFLUXDB_INIT_ORG=safe-org
      - DOCKER_INFLUXDB_INIT_BUCKET=telegraf
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$INFLUXDB_TOKEN
    volumes:
      # Make sure you create these local directories
      - $HOME/.local/share/tig-stack/influxdb/data:/var/lib/influxdb2
      - $HOME/.local/share/tig-stack/influxdb/config:/etc/influxdb2
    ports:
      - 8086:8086
    restart: unless-stopped
    networks:
      - tig_network
    healthcheck:
      test: "curl -f http://localhost:8086/ping"
      interval: 5s
      timeout: 10s
      retries: 5

  grafana:
    image: grafana/grafana-enterprise
    container_name: grafana
    user: "1000:1000"
    ports:
      - 3000:3000
    volumes:
      # Make sure you create these local directories
      - $HOME/.local/share/tig-stack/grafana/data:/var/lib/grafana
      - $HOME/.local/share/tig-stack/grafana/config:/etc/grafana
      - $HOME/.local/share/tig-stack/grafana/log:/var/log/grafana
    restart: unless-stopped
    environment:
       - GF_PATHS_CONFIG=/etc/grafana/custom.ini

    networks:
      - tig_network

networks:
  tig_network:
    driver: bridge
EOF


docker compose --project-directory $HOME/.local/share/tig-stack/ up


############################################################################################################################################## Install Docker Engine
elif [[ "$SELECTION" == "3" ]]; then

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

#test install with
#sudo docker run hello-world


#set up docker user so dont have to run all comands as roor or with sudo
sudo groupadd docker
sleep 1
sudo usermod -aG docker $USER
sleep 1
newgrp docker
sleep 1
# test without sudo

# to test install you can run 
#                                docker run hello-world

############################################################################################################################################## Exit
elif [[ "$SELECTION" == "4" ]]; then

exit 0

############################################################################################################################################### Stop & Uninstall TIG Stack
elif [[ "$SELECTION" == "5" ]]; then

echo " stoping docker containers"
docker compose --project-directory $HOME/.local/share/tig-stack/telegraf/ down
echo ""
sudo rm -rf $HOME/.local/share/tig-stack/

fi
