#!/usr/bin/env bash

CLIENT=0.90.4
NODE=0.105.6
FAUCET=188.166.171.13:8000
PEER="/ip4/165.227.225.208/udp/55913/quic-v1/p2p/12D3KooWJ6NwxiqMj9Xy6XzLS5GD2V9Ks4NvTLoXejQHXMcKP34k"
# get from https://sn-testnet.s3.eu-west-2.amazonaws.com/network-contacts

#run with
# bash <(curl -s https://raw.githubusercontent.com/safenetforum-community/TIG_Stack/main/maid.sh)

# first node port can edited in menu later
NODE_PORT_FIRST=4700
NUMBER_NODES=50
NUMBER_COINS=1
DELAY_BETWEEN_NODES=601
NODE_START_TIME=0

export NEWT_COLORS='
window=,white
border=black,white
textbox=black,white
button=black,white
'

############################################## select test net action

SELECTION=$(whiptail --title "Safe Network Testnet 1.1" --radiolist \
"Testnet Actions                              " 20 70 10 \
"1" "Install & Start Nodes " OFF \
"2" "Upgrade Client to Latest" OFF \
"3" "Stop Nodes" OFF \
"4" "Get Test Coins" ON \
"5" "Upgrade Nodes" OFF \
"6" "Start Vdash" OFF \
"7" "Update & Upgrade SYSTEM and RESTART!!   " OFF \
"8" "Add more nodes   " OFF 3>&1 1>&2 2>&3)

if [[ $? -eq 255 ]]; then
exit 0
fi

################################################################################################################ start or Upgrade Client & Node to Latest
if [[ "$SELECTION" == "1" ]]; then

# remove NTracking cron jobs temp til NTracking is fixed
sudo rm /etc/cron.d/ntracking*
# add cron job for tig stack on 5 min schedule
echo "*/5 * * * * $USER /usr/bin/mkdir -p /tmp/influx-resources && /bin/bash /usr/bin/influx-resources.sh > /tmp/influx-resources/influx-resources" | sudo tee /etc/cron.d/influx_resources

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
rm -rf  ~/.local/share/local_machine/


#install latest infux resources script from github
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
DELAY_BETWEEN_NODES=`echo $DELAY_BETWEEN_NODES*1000 | bc`
if [[ $? -eq 255 ]]; then
exit 0
fi

##############################  close fire wall
yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}')) && yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}'))
############################## Stop Nodes and delete safe folder

# sudo snap remove curl
# sudo apt install curl

# disable installing safe up for every run
#curl -sSL https://raw.githubusercontent.com/maidsafe/safeup/main/install.sh | bash
#source ~/.config/safe/env

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

safeup node-manager

cargo install vdash

############################## open ports
sudo ufw allow $NODE_PORT_FIRST:$(($NODE_PORT_FIRST+$NUMBER_NODES-1))/udp comment 'safe nodes'
sleep 2

############################## start nodes

mkdir -p /tmp/influx-resources

#sudo env "PATH=$PATH" safenode-manager add --node-port "$NODE_PORT_FIRST"-$(($NODE_PORT_FIRST+$NUMBER_NODES-1))  --count "$NUMBER_NODES"  --peer "$PEER"  --url http://safe-logs.ddns.net/safenode.tar.gz

sudo env "PATH=$PATH" safenode-manager add --node-port "$NODE_PORT_FIRST"-$(($NODE_PORT_FIRST+$NUMBER_NODES-1))  --count "$NUMBER_NODES"  --peer "$PEER" --version "$NODE"
sudo env "PATH=$PATH" safenode-manager start --interval $DELAY_BETWEEN_NODES | tee /tmp/influx-resources/nodemanager_output & disown



######################################################################################################################## Upgrade Client to Latest
elif [[ "$SELECTION" == "2" ]]; then
############################## Stop client and delete safe folder
rm -rf $HOME/.local/share/safe/client
# upgrade client and get some Coins
safeup client

#sudo env "PATH=$PATH" safenode-manager upgrade

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
rm -rf  ~/.local/share/local_machine/

sleep 2

sudo reboot

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

######################################################################################################################### Upgrade Nodes
elif [[ "$SELECTION" == "5" ]]; then
sudo rm /etc/cron.d/influx_resources
#safeup node-manager
mkdir -p /tmp/influx-resources
sudo env "PATH=$PATH" safenode-manager upgrade | tee /tmp/influx-resources/node_upgrade_report && echo "*/5 * * * * $USER /usr/bin/mkdir -p /tmp/influx-resources && /bin/bash /usr/bin/influx-resources.sh > /tmp/influx-resources/influx-resources" | sudo tee /etc/cron.d/influx_resources & disown
######################################################################################################################### Start Vdash
elif [[ "$SELECTION" == "6" ]]; then
vdash --glob-path "/var/log/safenode/*/safenode.log"
######################################################################################################################### update and restart
elif [[ "$SELECTION" == "7" ]]; then
rustup update
sudo apt update -y && sudo apt upgrade -y
sudo reboot

######################################################################################################################### add more nodes
elif [[ "$SELECTION" == "8" ]]; then

NUMBER_NODES=$(whiptail --title "Number of Nodes to start" --inputbox "\nEnter number of nodes" 8 40 $NUMBER_NODES 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi

NODE_PORT_FIRST=$(whiptail --title "Port Number of first Node" --inputbox "\nEnter Port Number of first Node" 8 40 $NODE_PORT_FIRST 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi

DELAY_BETWEEN_NODES=$(whiptail --title "Delay between starting nodes in seconds" --inputbox "\nEnter delay between nodes?" 8 40 $DELAY_BETWEEN_NODES 3>&1 1>&2 2>&3)
DELAY_BETWEEN_NODES=`echo $DELAY_BETWEEN_NODES*1000 | bc`
if [[ $? -eq 255 ]]; then
exit 0
fi

############################## open ports
sudo ufw allow $NODE_PORT_FIRST:$(($NODE_PORT_FIRST+$NUMBER_NODES-1))/udp comment 'safe nodes'
sleep 2

sudo env "PATH=$PATH" safenode-manager add --node-port "$NODE_PORT_FIRST"-$(($NODE_PORT_FIRST+$NUMBER_NODES-1))  --count "$NUMBER_NODES"  --peer "$PEER" --version "$NODE"
sudo env "PATH=$PATH" safenode-manager start --interval $DELAY_BETWEEN_NODES | tee /tmp/influx-resources/nodemanager_output & disown

fi
