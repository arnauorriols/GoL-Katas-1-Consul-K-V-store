CONSUL_HOST=172.17.0.2:8500

read -d'EOF' initial_board

echo "Initial board:"
echo "$initial_board"

grid_width=$(echo "$initial_board" | head -n 1 | wc -w)
grid_height=$(echo "$initial_board" | wc -l)
total_cells=$(( grid_width * grid_height - 1 ))
docker build -t gol.cell:latest -f Cell.GoL.Dockerfile .
docker build -t gol.conductor:latest -f Conductor.GoL.Dockerfile .
docker build -t gol.renderer:latest -f Renderer.GoL.Dockerfile .
docker run -d --name=consul consul agent -dev --client 0.0.0.0 -log-level info
docker run -d --name=conductor -e CONSUL_HOST=$CONSUL_HOST -e GRID_WIDTH=$grid_width -e GRID_HEIGHT=$grid_height gol.conductor:latest

cell_number=0
for cell_state in ${initial_board[@]}; do
    docker run -d --name=cell-$cell_number -e CONSUL_HOST=$CONSUL_HOST -e GRID_WIDTH=$grid_width -e GRID_HEIGHT=$grid_height -e CELL_NUMBER=$cell_number -e INITIAL_STATE=$cell_state gol.cell:latest
    cell_number=$(( cell_number + 1 ))
done

docker run -t --name=renderer -e CONSUL_HOST=$CONSUL_HOST -e GRID_WIDTH=$grid_width -e GRID_HEIGHT=$grid_height gol.renderer:latest
