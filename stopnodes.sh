#!/usr/bin/env bash
echo "stoping nodes"
sleep 1

for i in {51..100}
do
 # your-unix-command-here
 sudo systemctl disable --now safenode$i
 sudo rm /etc/systemd/system/safenode$i.service
sudo rm -rf /var/safenode-manager/services/safenode$i
sudo rm -rf /var/log/safenode/safenode$i

done

sudo systemctl daemon-reload


# remove NTracking cron jobs temp til NTracking is fixed
sudo rm /etc/cron.d/ntracking*
# add cron job for tig stack on 5 min schedule
echo "*/5 * * * * $USER /usr/bin/mkdir -p /tmp/influx-resources && /bin/bash /usr/bin/influx-resources.sh > /tmp/influx-resources/influx-resources" | sudo tee /etc/cron.d/influx_resources

#install latest infux resources script from github
sudo rm /usr/bin/influx-resources.sh* && sudo wget -P /usr/bin  https://raw.githubusercontent.com/safenetforum-community/TIG_Stack/main/influx-resources.sh && sudo chmod u+x /usr/bin/influx-resources.sh
