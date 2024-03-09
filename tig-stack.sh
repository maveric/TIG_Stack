#!/usr/bin/env bash

CLIENT=0.89.68
NODE=0.104.32
FAUCET=64.227.32.230:8000




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

########################################################################################################################### Install Telegraf
if [[ "$SELECTION" == "1" ]]; then


########################################################################################################################### Setup Influxdb2 & Grafana
elif [[ "$SELECTION" == "2" ]]; then


########################################################################################################################### Get Test Coins
elif [[ "$SELECTION" == "4" ]]; then

########################################################################################################################### Start Vdash
elif [[ "$SELECTION" == "5" ]]; then


fi
