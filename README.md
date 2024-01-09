# MQTT Topic Monitor

## Overview
This script monitors MQTT topics for message activity.
It can also execute an extra script in response to MQTT topic activity.
It can sends notifications to Slack with webhook

## Requirements
- Docker installed
- Access to MQTT broker
- Slack webhook URL (optional)

## Usage

### Docker Environment Variables
- `MQTT_BROKER_HOST`: MQTT broker hostname (default: localhost)
- `SLACK_WEBHOOK_URL`: Slack webhook URL for notifications (optional)
- `MAX_SILENT_TOPICS`: Maximum number of silent topics to trigger notifications (default: 2)
- `WAIT_TIMEOUT`: Wait time for checking messages on each topic (default: 60 seconds)
- `CHECK_INTERVAL`: Interval between checks (default: 3600 seconds)
- `TOPICS_FILE`: Path to the file containing MQTT topics list (default: /app/config/topics.txt)
- `CREDENTIALS_FILE`: Path to the file containing MQTT credentials in JSON format (default: /app/config/credentials.json)
- `PROCESS_SCRIPT`: Path to a script to run when triggered (default: /app/process.sh)
- `DEBUG`: Enable debugging (default: false)

### Building and Running
```bash
docker build -t mqtt-topic-monitor .
docker run --rm -it --name mqtt-topic-monitor -e MQTT_BROKER_HOST=<your_broker_host> -e SLACK_WEBHOOK_URL=<your_slack_webhook_url> mqtt-topic-monitor
```

## Configuration
- **MQTT Topics**: List of MQTT topics to monitor should be specified in the `topics.txt` file (default location: /app/config/topics.txt).

- **MQTT Credentials**: MQTT username and password should be provided in a JSON file (default location: /app/config/credentials.json).

- **Process Script**: If you want to run a script when triggered, specify its path in the `PROCESS_SCRIPT` environment variable.

### Configuration File

The script uses a configuration file specified by the `TOPICS_FILE` variable (default: `/app/config/topics.txt`) to specify MQTT topics to monitor. Each line in the file represents a topic.

### Authentication File

If MQTT authentication is required, specify the credentials in a file specified by the `CREDENTIALS_FILE` variable (default: `/app/config/credentials.json`). The file should be in JSON format with a structure like this:

```json
{
  "username": "your_username",
  "password": "your_password"
}
```

## Debugging
To enable debugging, set the `DEBUG` environment variable to `true`.

## License
This project is licensed under the [MIT License](LICENSE).
