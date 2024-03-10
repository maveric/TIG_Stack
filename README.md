# TIG_Stack Telegraf Influx Grafana
whiptail script to set up TIG stack 

# to Run

Do not tun as root user if you need to create a normal user with sudo rights and switch to that user.

```
adduser <username>
usermod -aG sudo <username>
su - u <username>
```

```bash <(curl -s https://raw.githubusercontent.com/safenetforum-community/TIG_Stack/main/tig-stack.sh)```

this script will run a whip tail menu script giving you the options to :

1. setup a dockerised  install of Telegraf which will send data to influxDB.
2. setup a dockerised install of Influxdb2 and Grafana to visualise data.
3. install Docker engine.
4. uninstall telegraf influx and grafana dockers.

Port 8086 will be opened by ufw to allow data ingress on the machine hosting Influxdb and Grafana

Docker Engine must be installed first on all machines

Telegraf must be installed on all machines that are to send data to influx including the one which hosts Influx and Grafana.


# Defaults for Influx and Grafana
username: ```safe```

password: ```jidjedewTSuIw4EmqhoOo```

These can be changed during the install via interactive prompt along with the TOKEN for data ingress to Influx2 Database

# How to access

Influx can be accesed on ```<IP Address>:8086```

Grafana can be accesed on ```<IP Address>:3000```

# Connecting Grafana to influx

1. Log into Grafana
2. Select add new data source
3. Search for InfluxDB
4. Enter details as below
5. click safe and test and if it goes green InfluxDB and Grafana are now connected.
![connect Grafana to influx](https://github.com/safenetforum-community/TIG_Stack/assets/25412853/2a1368de-bb40-49e3-98d3-1709934221bc)
