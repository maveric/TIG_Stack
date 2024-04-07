#!/usr/bin/env bash

for i in {56..100}
do
 # your-unix-command-here
 sudo systemctl disable --now safenode$i
 sudo rm /etc/systemd/system/safenode$i.service
sudo rm -rf /var/safenode-manager/services/safenode$i
sudo rm -rf /var/log/safenode/safenode$i

done

sudo systemctl daemon-reload
