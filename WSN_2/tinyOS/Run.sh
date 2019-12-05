#!/bin/bash
gcc -std=c99 -o topologyProgram topology.c 

echo -n "\n Topology Progam Running Before Simulation\n "
./topologyProgram
echo "Starting Simulation : "
make micaz sim
python mySimulation.py 