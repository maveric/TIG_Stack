# TIG_Stack
whiptail script to set up TIG stack 

# to Run

```bash <(curl -s https://raw.githubusercontent.com/safenetforum-community/TIG_Stack/main/tig-stack.sh)```

this script will run a whip tail menu script giving you the options to :

1. setup a dockerised  install of Telegraf which will send data to influxDB.
2. setup a dockerised install of Influxdb2 and Grafana to visualise data.
3. install Docker engine.
4. uninstall telegraf influx and grafana dockers.


# Defaults for Influx and Grafana
username: safe
password: jidjedewTSuIw4EmqhoOo

These can be changed during the install via interactive prompt along with the TOKEN for data ingress to Influx2 Database

#Access

Influx can be accesed on ```<IP Address>:8086```

Grafana can be accesed on ```<IP Address>:3000```
