#!/usr/bin/env bash

CLIENT=0.91.0-alpha.4
NODE=0.106.0-alpha.5
FAUCET=209.97.185.196:8000
PEER="/ip4/144.126.234.162/udp/37284/quic-v1/p2p/12D3KooWFTMioLueKChk9rWEFNFGTH3zRQ6eTiGxjL2ss1wWgZ11"
# get from https://sn-testnet.s3.eu-west-2.amazonaws.com/network-contacts


#run with
# bash <(curl -s https://raw.githubusercontent.com/safenetforum-community/TIG_Stack/main/maid.sh)

# first node port can edited in menu later
NODE_PORT_FIRST=4700
NUMBER_NODES=50
NUMBER_COINS=1
CPU_TARGET=60
DELAY_BETWEEN_NODES=11000

export NEWT_COLORS='
window=,white
border=black,white
textbox=black,white
button=black,white
'

############################################## select test net action

SELECTION=$(whiptail --title "Safe Network Testnet 1.3" --radiolist \
"Testnet Actions                              " 20 70 10 \
"1" "Install & Start Nodes " OFF \
"2" "Upgrade Client to Latest" OFF \
"3" "Stop Nodes" OFF \
"4" "Get Test Coins" ON \
"5" "Upgrade Nodes" OFF \
"6" "Start Vdash" OFF \
"7" "Spare                        " OFF \
"8" "Spare   " OFF 3>&1 1>&2 2>&3)

if [[ $? -eq 255 ]]; then
exit 0
fi

################################################################################################################ start or Upgrade Client & Node to Latest
if [[ "$SELECTION" == "1" ]]; then


NODE_TYPE=$(whiptail --title "Safe Network Testnet 1.0" --radiolist \
"Type of Nodes to start                              " 20 70 10 \
"1" "Node from home no port forwarding    " ON \
"2" "Cloud based nodes with port forwarding   " OFF 3>&1 1>&2 2>&3)

if [[ $? -eq 255 ]]; then
exit 0
fi

#install latest infux resources script from github
sudo rm /usr/bin/influx-resources.sh* && sudo wget -P /usr/bin  https://raw.githubusercontent.com/safenetforum-community/TIG_Stack/main/influx-resources.sh && sudo chmod u+x /usr/bin/influx-resources.sh


NUMBER_NODES=$(whiptail --title "Number of Nodes to start" --inputbox "\nEnter number of nodes" 8 40 $NUMBER_NODES 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi


if [[ "$NODE_TYPE" == "2" ]]; then

NODE_PORT_FIRST=$(whiptail --title "Port Number of first Node" --inputbox "\nEnter Port Number of first Node" 8 40 $NODE_PORT_FIRST 3>&1 1>&2 2>&3)
if [[ $? -eq 255 ]]; then
exit 0
fi
############################## open ports
sudo ufw allow $NODE_PORT_FIRST:$(($NODE_PORT_FIRST+$NUMBER_NODES-1))/udp comment 'safe nodes'
sleep 2

fi

##############################  close fire wall
yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}')) && yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}'))
############################## Stop Nodes and delete safe folder

sudo env "PATH=$PATH" safenode-manager reset
rm -rf  ~/.local/share/local_machine/

# sudo snap remove curl
# sudo apt install curl

# disable installing safe up for every run
#curl -sSL https://raw.githubusercontent.com/maidsafe/safeup/main/install.sh | bash
#source ~/.config/safe/env

rm -rf $HOME/.local/share/safe/node

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
safeup client --version "$CLIENT"

cargo install vdash

############################## start nodes

mkdir -p /tmp/influx-resources

if [[ "$NODE_TYPE" == "2" ]]; then
# for cloud instances
sudo env "PATH=$PATH" safenode-manager add --node-port "$NODE_PORT_FIRST"-$(($NODE_PORT_FIRST+$NUMBER_NODES-1))  --count "$NUMBER_NODES" --version "$NODE"

else
# for home nodes hole punching
sudo env "PATH=$PATH" safenode-manager add --home-network --count "$NUMBER_NODES" --version "$NODE"
fi

sudo env "PATH=$PATH" safenode-manager start --interval $DELAY_BETWEEN_NODES | tee /tmp/influx-resources/nodemanager_output & disown

#sudo env "PATH=$PATH" safenode-manager add --node-port "$NODE_PORT_FIRST"-$(($NODE_PORT_FIRST+$NUMBER_NODES-1))  --count "$NUMBER_NODES"  --peer "$PEER"  --url http://safe-logs.ddns.net/safenode.tar.gz


# FOR USE UNTILL TESTING --INTERVAL IS COMPLETED

#sudo apt install sysstat -y

#wait_for_cpu_usage()
#{
#    current=$(mpstat 1 1 | awk '$13 ~ /[0-9.]+/ { print int(100 - $13 + 0.5) }')
#    while [[ "$current" -ge "$1" ]]; do
#        current=$(mpstat 1 1 | awk '$13 ~ /[0-9.]+/ { print int(100 - $13 + 0.5) }')
#        sleep 30
#    done
#}

#(for ((i=1;i<=$NUMBER_NODES;i++)); do
#    sudo env "PATH=$PATH" safenode-manager start --service-name safenode$i | tee /tmp/influx-resources/nodemanager_output
#    sleep 301
#    wait_for_cpu_usage $CPU_TARGET
#done) & disown



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

sudo pkill -e safe

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

rm -rf  ~/.local/share/local_machine/

sleep 2


############################## close fire wall

yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}')) && yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}'))
yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}')) && yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}'))
yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}')) && yes y | sudo ufw delete $(sudo ufw status numbered |(grep 'safe nodes'|awk -F"[][]" '{print $2}'))

rustup update
sudo apt update -y && sudo apt upgrade -y
sudo reboot


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

sudo env "PATH=$PATH" safenode-manager upgrade --interval 11000  | tee -a /tmp/influx-resources/node_upgrade_report

######################################################################################################################### Start Vdash
elif [[ "$SELECTION" == "6" ]]; then
vdash --glob-path "/var/log/safenode/*/safenode.log"
######################################################################################################################### spare
elif [[ "$SELECTION" == "7" ]]; then

echo "spare 7"

######################################################################################################################### spare
elif [[ "$SELECTION" == "8" ]]; then

echo "spare 8"


fi
