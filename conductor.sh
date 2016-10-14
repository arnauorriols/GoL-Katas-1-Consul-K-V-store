#!/usr/bin/env bash

total_cells=$(( $GRID_WIDTH * $GRID_HEIGHT - 1))

ensure_leading_zeros() {
    cell_number=$1
    echo $(printf "%0*d " $leading_zeros $cell_number)
}

export leading_zeros=${#total_cells}
export -f ensure_leading_zeros

get_cell_data() {
    args=($@)
    cell=${args[0]}
    cells_indexes=(${args[@]:1})
    cell_index=$(curl -s http://$CONSUL_HOST/v1/kv/cells/$cell?index=${cells_indexes[10#$cell]} | jq -r '.[0].ModifyIndex')
    echo "$cell,$cell_index"
}

export -f get_cell_data

store_cell_data() {
    cells_data=( $1 )
    for cell_data in ${cells_data[@]}; do
        cell_number=$(echo $cell_data | cut -d',' -f1)
        cell_index=$(echo $cell_data | cut -d',' -f2)
        cells_indexes[10#$cell_number]=$cell_index
    done
}

cells=$(
    seq 0 $total_cells \
    | grep -o '[0-9]*' \
    | xargs -I {cell} bash -c "ensure_leading_zeros {cell}"
)

# Resources
# ---------
# - /cells/<cell_n>: current state of the cell. Serves as signaling device (cell state changed)
# - /round: current round. Serves as signaling device (start new round)
# - /round/<round_n>/cells/<cell_n>: immutable state of a cell in a particular round
echo "Setting up resources..."
for cell in ${cells[@]}; do
    curl -X PUT -d '0' --output /dev/null -s http://$CONSUL_HOST/v1/kv/cells/$cell
    cells_indexes[10#$cell]=$(curl -s http://$CONSUL_HOST/v1/kv/cells/$cell | jq -r '.[0].ModifyIndex')
done
echo "Run!"

round=0

while true; do
    curl -X PUT -d "$round" --output /dev/null -s http://$CONSUL_HOST/v1/kv/round
    new_cells_indexes=$(
        echo ${cells[@]} \
        | grep -o '[0-9]*' \
        | xargs -P $total_cells -I {cell} bash -c "get_cell_data {cell} $(echo ${cells_indexes[@]})"
    )
    store_cell_data $new_cells_indexes
    round=$(( round + 1 ))
done
