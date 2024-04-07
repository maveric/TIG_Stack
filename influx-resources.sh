#!/bin/bash

export PATH=$PATH:$HOME/.local/bin

base_dirs="/var/safenode-manager/services"

# influx db and grafana need data that is to be worked with to have the same time stamp this rounds time to the nearest 100 seconds to
# attempt to keep all machines in sync for time purposes
influx_time="$(echo "$(date +%s%N)" | awk '{printf "%d0000000000\n", $0 / 10000000000}')"



######################################################
# coin gecko gets upset with to many requests this atempts to get the exchange every 15 min
# https://www.coingecko.com/api/documentation
######################################################
time_min=$(date +"%M")
CALCULATE_EARNINGS=0
# execute script every 15 min if the tig stack folder is present
if [ $time_min == 0 ] || [ $time_min == 15 ] || [ $time_min == 30 ] || [ $time_min == 45 ]
then
CALCULATE_EARNINGS=1
fi


total_disk=0
total_records=0
total_rewards_balance=0
total_nodes_started=0

declare -A dir_pid
declare -A dir_peer_ids
declare -A node_numbers
declare -A dir_creation_times

# Latency
latency=$(ping -c 4 8.8.8.8 | tail -1| awk '{print $4}' | cut -d '/' -f 2)

#get node overview from safe node manager
safenode-manager status --details > /tmp/influx-resources/nodes_overview

# Discover nodes, capture their details, and conditionally fetch Peer IDs
for base_dir in "${base_dirs[@]}"; do
    for dir in "$base_dir"/*; do
        if [[ -f "$dir/safenode.pid" ]]; then
            dir_name=$(basename "$dir")
            dir_pid["$dir_name"]=$(cat "$dir/safenode.pid")
            dir_creation_times["$dir_name"]=$(stat -c %W "$dir")  # Capture creation time

            # Assign a new number to unregistered nodes
            [[ -z ${node_numbers["$dir_name"]} ]] && node_numbers["$dir_name"]=$((++max_number))

            if [[ "$base_dir" == "/var/safenode-manager/services" ]]; then
                # Fetch the Peer ID by parsing `safenode-manager status --details`
				peer_id=$(echo "$(</tmp/influx-resources/nodes_overview)" | grep -A 5 "$dir_name - RUNNING" | grep "Peer ID:" | awk '{print $3}')
                dir_peer_ids["$dir_name"]="$peer_id"
            fi
        fi
    done
done

# Sort nodes by creation time and log their details
readarray -t sorted_dirs < <(for dir_name in "${!node_numbers[@]}"; do printf "%s:%s\n" "${node_numbers[$dir_name]}" "$dir_name"; done | sort -n | cut -d: -f2)
for dir_name in "${sorted_dirs[@]}"; do

#  echo "------------------------------------------"
#  echo "Global (UTC) Timestamp: $(date +%s)"
Number=${node_numbers[$dir_name]}
#  echo "Node: $dir_name"
NUMBER="$dir_name"
#  echo "PID: ${dir_pid[$dir_name]}"
PID=${dir_pid[$dir_name]}

if [[ -n "${dir_peer_ids[$dir_name]}" ]]; then
#  echo "Peer ID: ${dir_peer_ids[$dir_name]}"
ID="${dir_peer_ids[$dir_name]}"
fi

# Retrieve process information
process_info=$(ps -o rss,%cpu -p "${dir_pid[$dir_name]}" | awk 'NR>1')
if [[ -n "$process_info" ]]; then
    status=TRUE
    mem_used=$(echo "$process_info" | awk '{print $1/1024}')
    cpu_usage=$(echo "$process_info" | awk '{print $2}')
else
    status=FALSE
    mem_used=0.0
    cpu_usage=0.0
fi


# Check for record store and report its details
  record_store_dirs="$base_dirs/$dir_name/record_store"
  if [[ -d "$record_store_dirs" ]]; then
    records=$(find "$record_store_dirs" -type f | wc -l)
    records=$records
    disk=$(echo "scale=0;("$(du -s "$record_store_dirs" | cut -f1)")/1024" | bc)
  else
    #echo "$dir_name does not contain record_store"
        records=0
        disk=0.0
  fi

  # Retrieve and display rewards balance
rewards_balance=$(${HOME}/.local/bin/safe wallet balance --peer-id="$base_dirs/$dir_name" | grep -oP '(?<=: )\d+\.\d+')
#  echo "Rewards balance: $rewards_balance"


echo "nodes,service_number=$NUMBER,id=$ID cpu=$cpu_usage,mem=$mem_used,status=$status,pid=$PID"i",records=$records"i",disk=$disk,rewards=$rewards_balance $influx_time"


total_disk=`echo $total_disk+$disk | bc`
total_records=`echo $total_records+$records | bc`
total_rewards_balance=`echo $total_rewards_balance+$rewards_balance | bc`
total_nodes_started=`echo $total_nodes_started+1 | bc`

done

echo "nodes,id=total total_disk=$total_disk,total_records=$total_records,total_rewards=$total_rewards_balance,total_nodes_started=$total_nodes_started $influx_time"


echo "nodes latency=$latency $influx_time"


######################################################
# coin gecko gets upset with to many requests this atempts to get the exchange every 15 min
# https://www.coingecko.com/api/documentation
######################################################

# execute script every 15 min if the tig stack folder is present
if [ "$CALCULATE_EARNINGS"="1" ]
then

coingecko=$(curl -s -X 'GET' 'https://api.coingecko.com/api/v3/simple/price?ids=maidsafecoin&vs_currencies=gbp%2Cusd&include_market_cap=true' -H 'accept: application/json')
exchange_rate_gbp=$(awk -F'[:,]' '{print $3}' <<< $coingecko)
market_cap_gbp=$(awk -F'[:,]' '{print $5}' <<< $coingecko)
exchange_rate_usd=$(awk -F'[:,]' '{print $7}' <<< $coingecko)
market_cap_usd=$(awk -F'[:}]' '{print $6}' <<< $coingecko)

# calculate earnings in usd & gbp
earnings_gbp=`echo $total_rewards_balance*$exchange_rate_gbp | bc`
earnings_usd=`echo $total_rewards_balance*$exchange_rate_usd | bc`

echo "coingecko,curency=gbp exchange_rate=$exchange_rate_gbp,marketcap=$market_cap_gbp,earnings=$earnings_gbp  $influx_time"
echo "coingecko,curency=usd exchange_rate=$exchange_rate_usd,marketcap=$market_cap_usd,earnings=$earnings_usd  $influx_time"
fi
