#!/usr/bin/env bash

CLIENT=0.89.85
NODE=0.104.41
FAUCET=178.128.175.208:8000
PEER="/ip4/44.214.100.193/udp/12001/quic-v1/p2p/12D3KooWE4gNLSEHjKrWfhNb4adk8U3cNJmPHDrqoShQ3xfyrgwH"

# first node port can edited in menu later
NODE_PORT_FIRST=4700
NUMBER_NODES=30
NUMBER_COINS=1
DELAY_BETWEEN_NODES=11
NODE_START_TIME=0

export NEWT_COLORS='
window=,white
border=black,white
textbox=black,white
button=black,white
'

############################################## select test net action

SELECTION=$(whiptail --title "Safe Network Testnet" --radiolist \
"Testnet Actions                              " 20 70 10 \
"1" "Start Node & upgrade client to Latest" OFF \
"2" "Upgrade Nodes & Client to Latest" OFF \
"3" "Stop Nodes" OFF \
"4" "Get Test Coins" ON \
"5" "Start Vdash" OFF \
"6" "Update & Upgrade SYSTEM and RESTART!!   " OFF 3>&1 1>&2 2>&3)

if [[ $? -eq 255 ]]; then
exit 0
fi

################################################################################################################ start or Upgrade Client & Node to Latest
if [[ "$SELECTION" == "1" ]]; then

# nuke safe node manager services 1 - 100 untill nuke comand exists

for i in {1..100}
do
 # your-unix-command-here
 sudo systemctl disable --now safenode$i
done

sudo rm /etc/systemd/system/safenode*
sudo systemctl daemon-reload

sudo rm -rf /var/safenode-manager
sudo rm -rf /var/log/safenode



#remove old script if exists
sudo rm /usr/bin/influx-resources.sh*
# download latest script from git hub
sudo wget -P /usr/bin  https://raw.githubusercontent.com/safenetforum-community/TIG_Stack/main/influx-resources.sh
#make executable
sudo chmod u+x /usr/bin/influx-resources.sh

#install new script
sudo rm /usr/bin/influx-resources.sh* && sudo wget -P /usr/bin  https://raw.githubusercontent.com/safenetforum-community/TIG_Stack/main/influx-resources.sh && sudo chmod u+x /usr/bin/influx-resources.sh


NUMBER_NODES=$(whiptail --title "Number of Nodes to start" --inputbox "\nEnter number of nodes" 8 40 $NUMBER_NODES 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi

NODE_PORT_FIRST=$(whiptail --title "Port Number of first Node" --inputbox "\nEnter Port Number of first Node" 8 40 $NODE_PORT_FIRST 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi

DELAY_BETWEEN_NODES=$(whiptail --title "Delay between starting nodes in seconds" --inputbox "\nEnter delay between nodes?" 8 40 $DELAY_BETWEEN_NODES 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi

############################## count nodes directories and close fire wall
yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}')) && yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}'))
############################## Stop Nodes and delete safe folder

# sudo snap remove curl
# sudo apt install curl

curl -sSL https://raw.githubusercontent.com/maidsafe/safeup/main/install.sh | bash

rm -rf $HOME/.local/share/safe

# remove ntracking logs
rm -rf $HOME/.local/share/local_machine
rm -rf $HOME/.local/share/ntracking/logs
rm $HOME/.local/share/ntracking/*.log

cp $HOME/.local/share/ntracking/index.html.standby /var/www/ntracking/index.html

## reset vnstat database
sudo systemctl stop vnstat.service
sudo rm -rf /var/lib/vnstat/
sudo systemctl start vnstat.service

sleep 2
############################## install client node and vdash
# Source the environment variables
source /root/.config/safe/env


safeup client --version "$CLIENT"
safeup node-manager

cargo install vdash

############################## open ports
sudo ufw allow $NODE_PORT_FIRST:$(($NODE_PORT_FIRST+$NUMBER_NODES-1))/udp comment 'safe nodes'
sleep 2

############################## start nodes

sudo env "PATH=$PATH" safenode-manager add --port "$NODE_PORT_FIRST"-$(($NODE_PORT_FIRST+$NUMBER_NODES-1))  --count "$NUMBER_NODES"  --peer "$PEER"  --version "$NODE"

for ((i=1;i<=$NUMBER_NODES;i++)); do

    sudo env "PATH=$PATH" safenode-manager start --service-name safenode$i
    sleep $DELAY_BETWEEN_NODES
done



######################################################################################################################## Upgrade Client to Latest
elif [[ "$SELECTION" == "2" ]]; then
############################## Stop client and delete safe folder
rm -rf $HOME/.local/share/safe/client
# upgrade client and get some Coins
safeup client

sudo env "PATH=$PATH" safenode-manager upgrade

sleep 2
safe wallet get-faucet "$FAUCET"

######################################################################################################################## Stop Nodes
elif [[ "$SELECTION" == "3" ]]; then

# stop nodes
# nuke safe node manager services 1 - 100 untill nuke comand exists

for i in {1..100}
do
 # your-unix-command-here
 sudo systemctl disable --now safenode$i
done

sudo rm /etc/systemd/system/safenode*
sudo systemctl daemon-reload

sudo rm -rf /var/safenode-manager
sudo rm -rf /var/log/safenode


############################## close fire wall

yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}')) && yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}'))

######################################################################################################################## Get Test Coins
elif [[ "$SELECTION" == "4" ]]; then
NUMBER_COINS=$(whiptail --title "Number of Coins" --inputbox "\nEnter number of deposits 100 each" 8 40 $NUMBER_COINS 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi

for (( c=1; c<=$NUMBER_COINS; c++ ))
do
   safe wallet get-faucet "$FAUCET"
   sleep 1
done
######################################################################################################################### Start Vdash
elif [[ "$SELECTION" == "5" ]]; then
vdash --glob-path "/var/log/safenode/*/safenode.log"

######################################################################################################################### update and restart
elif [[ "$SELECTION" == "6" ]]; then
rustup update
sudo apt update -y && sudo apt upgrade -y
sudo reboot

fi
