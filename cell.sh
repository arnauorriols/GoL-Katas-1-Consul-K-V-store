#!/usr/bin/env bash

row=$(( $CELL_NUMBER / $GRID_WIDTH ))
column=$(( $CELL_NUMBER % $GRID_WIDTH ))
total_cells=$(( GRID_WIDTH * $GRID_HEIGHT - 1 ))

calculate_neighbour_number() {
    relative_x=$1
    relative_y=$2
    echo $(( (((($CELL_NUMBER + $relative_x - $GRID_WIDTH) % $GRID_WIDTH) + $GRID_WIDTH) % $GRID_WIDTH) + ($GRID_WIDTH * (((($row + $relative_y) % $GRID_HEIGHT) + $GRID_HEIGHT) % $GRID_HEIGHT)) ))
}

update_state() {
    state=$1
    round=$2
    curl -X PUT -d "$state" --output /dev/null -s http://$CONSUL_HOST/v1/kv/round/$round/cells/$(ensure_leading_zeros $CELL_NUMBER)
    curl -X PUT -d "$state" --output /dev/null -s http://$CONSUL_HOST/v1/kv/cells/$(ensure_leading_zeros $CELL_NUMBER)
}

ensure_leading_zeros() {
    cell_number=$1
    echo $(printf "%0*d " $leading_zeros $cell_number)
}

export leading_zeros=${#total_cells}
export -f ensure_leading_zeros

neighbours=(
    $(calculate_neighbour_number -1 -1)
    $(calculate_neighbour_number 0 -1)
    $(calculate_neighbour_number 1 -1)
    $(calculate_neighbour_number -1 0)
    $(calculate_neighbour_number 1 0)
    $(calculate_neighbour_number -1 +1)
    $(calculate_neighbour_number 0 +1)
    $(calculate_neighbour_number 1 +1)
)

echo "Waiting for game to begin..."  # print waiting dots in newline, otherwise docker won't log anything until waiting is done
until curl -s --fail --output /dev/null http://$CONSUL_HOST/v1/kv/round;
do
    printf "."
    sleep 1
done
echo ": READY"

state=$INITIAL_STATE

update_state $state 0

round_index=$(curl -s http://$CONSUL_HOST/v1/kv/round | jq -r '.[0].ModifyIndex')

while true; do
    round_data=$(curl -s http://$CONSUL_HOST/v1/kv/round?index=$round_index)
    round=$(echo $round_data | jq -r '.[0].Value' | base64 -d)
    round_index=$(echo $round_data | jq -r '.[0].ModifyIndex')
    neighbours_alive=$(
        echo ${neighbours[@]} \
        | grep -o '[0-9]*' \
        | xargs -I {neighbour} bash -c "ensure_leading_zeros {neighbour}" \
        | xargs -I {neighbour} curl -s http://$CONSUL_HOST/v1/kv/round/$(( round - 1 ))/cells/{neighbour}?raw \
        | grep -o . \
        | paste -sd+ - \
        | bc
    )
    if (( $state == 1 ))
    then
        if (( neighbours_alive < 2 | neighbours_alive > 3 )); then
            state=0
        fi
    else
        if (( neighbours_alive == 3 )); then
            state=1
        fi
    fi
    update_state $state $round
done
