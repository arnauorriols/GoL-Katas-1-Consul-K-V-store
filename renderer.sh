#!/usr/bin/env bash

echo "Waiting for game to begin..."  # print waiting dots in newline, otherwise docker won't log anything until waiting is done
until curl -s --fail --output /dev/null http://$CONSUL_HOST/v1/kv/round;
do
    printf "."
    sleep 1
done
echo ": READY"

round_data=$();
round_index=$(curl -s http://$CONSUL_HOST/v1/kv/round | jq -r '.[0].ModifyIndex')

while true; do
    round_data=$(curl -s http://$CONSUL_HOST/v1/kv/round?index=$round_index)
    # Unknown Consul issue, sometimes "4" is returned
    if [ $round_data == 4 ]; then
        continue
    fi
    round=$(echo $round_data | jq -r '.[0].Value' | base64 -d)
    round_index=$(echo $round_data | jq -r '.[0].ModifyIndex')
    cells_state=$(
        curl -s http://$CONSUL_HOST/v1/kv/round/$(( round -1 ))/cells?recurse \
        | jq -r '.[].Value' \
        | base64 -d
    )
    clear
    echo
    echo "Game Of Life, Consul K/V Style. Round $round" 
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo
    for row in $(seq 0 $(( GRID_HEIGHT - 1 ))); do
        echo -e "\t $(
            echo "${cells_state:(( row * GRID_WIDTH )):GRID_WIDTH}" \
            | tr 1 X \
            | fold -w1 \
            | paste -sd' '
        )"
    done
    echo
done
