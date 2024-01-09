#!/bin/bash

echo -e "
   __  __   ____  _______  _______          
 |  \/  | / __ \|__   __||__   __|         
 | \  / || |  | |  | |      | |            
 | |\/| || |  | |  | |      | |            
 | |  | || |__| |  | |      | |            
 |_|  |_| \___\_\  |_|      |_|            
  __  __                _  _               
 |  \/  |              (_)| |              
 | \  / |  ___   _ __   _ | |_  ___   _ __ 
 | |\/| | / _ \ | '_ \ | || __|/ _ \ | '__|
 | |  | || (_) || | | || || |_| (_) || |   
 |_|  |_| \___/ |_| |_||_| \__|\___/ |_|                                       

--------------------------------------------------
Author: Kevin Lambard <kevin.lambard@gmail.com>
Github: https://github.com/kinouzero/mqtt-monitor
License: This project is licensed under the MIT License.
--------------------------------------------------
"

# Docker environment variables
MQTT_BROKER_HOST=${MQTT_BROKER_HOST:-localhost}
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-}
MAX_SILENT_TOPICS=${MAX_SILENT_TOPICS:-2}
WAIT_TIMEOUT=${WAIT_TIMEOUT:-60}
CHECK_INTERVAL=${CHECK_INTERVAL:-3600}
TOPICS_FILE=${TOPICS_FILE:-/app/config/topics.txt}
CREDENTIALS_FILE=${CREDENTIALS_FILE:-/app/config/credentials.json}
PROCESS_SCRIPT=${PROCESS_SCRIPT:-/app/process.sh}
DEBUG=${DEBUG:-false}

# Ensure the TERM variable is set for tput
export TERM=xterm

# Function to send a notification to Slack with MQTT topics without messages and run an extra script
handle_action() {
  local dead_topics=("$@")
  local message="No messages received for more than ${WAIT_TIMEOUT}s for the following topics:"

  for topic in "${dead_topics[@]}"; do
    message+="\n- $topic"
  done

  # Check if Slack webhook URL is provided and if the extra script exists
  if [ -e "$PROCESS_SCRIPT" ]; then
    message+="\nProcessing..."
  fi

  # Use curl to send the message to the Slack webhook
  [ -n "$SLACK_WEBHOOK_URL" ] && curl -s -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message\"}" "$SLACK_WEBHOOK_URL"

  # Print the message if debugging is enabled
  $DEBUG && echo "$message"

  # Run the extra script if provided
  [ -e "$PROCESS_SCRIPT" ] && [ -x "$PROCESS_SCRIPT" ] && "$PROCESS_SCRIPT"
}

# Read topics and credentials from configuration files
topics=($(cat "$TOPICS_FILE"))
MQTT_USERNAME=$(jq -r '.username' < "$CREDENTIALS_FILE")
MQTT_PASSWORD=$(jq -r '.password' < "$CREDENTIALS_FILE")

# Print topics list if debugging is enabled
echo "Watched topics:"
for topic in "${dead_topics[@]}"; do
  echo "\n- $topic"
done

# Print credential information if debugging is enabled
$DEBUG && echo "Credentials file path: $CREDENTIALS_FILE" && echo "MQTT username: $MQTT_USERNAME" && echo "MQTT password: $MQTT_PASSWORD"

# Build the mosquitto_sub command with credentials if provided
mqtt_sub_cmd="/usr/bin/mosquitto_sub -h $MQTT_BROKER_HOST"
[ -n "$MQTT_USERNAME" ] && [ -n "$MQTT_PASSWORD" ] && mqtt_sub_cmd+=" -u $MQTT_USERNAME -P $MQTT_PASSWORD"

# Main loop to monitor MQTT topics
while true; do
  echo "Checking MQTT topics..."
  dead_topics=()
  
  # Iterate through each topic and check for messages
  for topic in "${topics[@]}"; do
    # Print mosquitto_sub command if debugging is enabled
    $DEBUG && echo "$mqtt_sub_cmd -W $WAIT_TIMEOUT -t $topic"

    # Execute mosquitto_sub in the background, redirecting output to a temporary file
    tmp_file=$(mktemp)
    echo "Executing mosquitto_sub with ${WAIT_TIMEOUT}s timeout for topic: $topic..."
    $mqtt_sub_cmd -W $WAIT_TIMEOUT -t "$topic" 2>/dev/null | awk '{$1=$1};1' > "$tmp_file" &

    # Wait for mosquitto_sub to finish
    wait $!
  
    # Count the number of lines in the temporary file
    nb_line=$(grep -c '[^[:space:]]' "$tmp_file")
  
    # Check for the presence of messages
    if [ "$nb_line" -lt 2 ]; then
      echo "No message received for the topic $topic"
      dead_topics+=("$topic")
    elif [ "$nb_line" -ge 2 ]; then
      echo "Number of messages received for $topic in ${WAIT_TIMEOUT}s: $nb_line"
    fi
  
    # Remove the temporary file
    rm -f "$tmp_file"
  done
  
  # Check if the maximum number of silent topics has been reached
  [ "${#dead_topics[@]}" -ge "$MAX_SILENT_TOPICS" ] && echo "Max silent topics reached handling actions..." && handle_action "${dead_topics[@]}"

  echo "Number of dead topics: ${#dead_topics[@]}"
  echo "Waiting ${CHECK_INTERVAL}s for next run..."

  # Wait before the next iteration
  sleep $CHECK_INTERVAL
done
