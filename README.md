# TIG_Stack Telegraf Influx Grafana
![image](https://github.com/safenetforum-community/TIG_Stack/assets/25412853/b3d390e9-e50b-44cb-b174-19a2cfd58e91)

whiptail script to set up TIG stack 

# Prereq

Do not run as root user if you need to create a normal user with sudo rights and switch to that user.

```
adduser <username>
usermod -aG sudo <username>
su - u <username>
```

# to Run

```bash <(curl -s https://raw.githubusercontent.com/safenetforum-community/TIG_Stack/main/tig-stack.sh)```

this script will run a whip tail menu script giving you the options to :

1. install Docker engine.
2. setup a dockerised install of Influxdb2 and Grafana to visualise data.
3. setup an install of Telegraf which will send data to influxDB.
4. uninstall telegraf influx and grafana.

Docker Engine must be installed first on all machines

Telegraf must be installed on all machines that are to send data to influx including the one which hosts Influx and Grafana.


# Defaults for Influx and Grafana
username: ```safe```

password: ```jidjedewTSuIw4EmqhoOo```

Influxdb default Token ```HYdrv1bCZhsvMhYOq6_wg4NGV2OI9HZch_gh57nquSdAhbjhLMUIeYnCCAoybgJrJlLXRHUnDnz2v-xR0hDt3Q==```

These can be changed during the install via interactive prompt along with the TOKEN for data ingress to Influx2 Database

# How to access

Influx can be accesed on ```<IP Address>:8086```

Grafana can be accesed on ```<IP Address>:3000```

# Connecting Grafana to influx

1. Log into Grafana
2. Select add new data source
3. Search for InfluxDB
4. Enter details as below using the ip or hostname and port of the fluxdb install you are connecting to
5. click safe and test and if it goes green InfluxDB and Grafana are now connected.
![connect Grafana to influx](https://github.com/safenetforum-community/TIG_Stack/assets/25412853/8cd2e8b6-7b32-4d9c-b10c-4cfd5b77deca)

# Import Grafana dashboard

after connecting Grafana and InfluxDB select the option to import Dashboard

1. copy the Dashboard json from the file https://github.com/safenetforum-community/TIG_Stack/blob/main/Grafana%20Dashboard%20json
2. paste it into the import dashboard window and save
3. refresh Grafana and load the dashboard



