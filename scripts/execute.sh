#!/bin/bash

IP=$1   #TODO: update
PORT=$2 # TODO: update
MAX_COMMANDS=1
#curl "http://localhost:3005/command/pending?hostName=localhost&maxCommand=1"
echo "Checking for pending execution requests..."

RESPONSE=$(curl --request GET \
	--url "http://$IP:$PORT/command/pending?hostName=$HOSTNAME&maxCommands=$MAX_COMMANDS" \
	--header 'content-type: application/json')

echo "Response: $RESPONSE"
#COMMANDS=$(echo $RESPONSE | jq -r '.commands')
COMMANDS=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['commands'])")
NUM_COMMANDS=$(echo $RESPONSE | python3 -c "import sys, json; print(len(json.load(sys.stdin)['commands'])-1)")
echo $NUM_COMMANDS
echo $COMMANDS
#COMMAND=$(echo $RESPONSE | jq -r '.commands[0].command')
RESULT="{\"executions\": ["
if [[ -n "$COMMANDS" ]]; then
	for i in $(seq 0 $NUM_COMMANDS); do
		COMMAND=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['commands'][${i}]['command'])")
		#		COMMAND=$(echo "$entry" | jq -r '.command')
		if [[ -n "$COMMAND" && "$COMMAND" != 'null' ]]; then
			if [[ $i -gt 1 ]]; then
				RESULT="$RESULT,"
			fi
			echo "Running command $COMMAND"
			CONSOLE_OUTPUT=$($COMMAND | tr '\n' ' ')
			REQUEST_ID=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['commands'][${i}]['requestId'])")
			STATUS_CODE="$?"
			NEXT_RECORD="{\"requestId\": \"$REQUEST_ID\",\"statusCode\":\"$STATUS_CODE\", \"consoleOutput\": \"$CONSOLE_OUTPUT\"}"
			RESULT="$RESULT$NEXT_RECORD"
		else
			echo "No more execution commands"
			break
		fi
	done

	if [[ $NUM_COMMANDS -gt -1 ]]; then
		RESULT="$RESULT]}"
		echo "Sending result $RESULT"
		curl -H "Content-Type: application/json" \
			--request PUT \
			--data "$RESULT" \
			"http://$IP:$PORT/command/result"
	fi
#	echo "Executing command: $COMMAND"

#	$COMMAND
else
	"Echo no pending commands"
fi
