# Dockerfile

FROM alpine:latest

RUN apk add --no-cache mosquitto-clients curl openssh-client bash jq nano ncurses coreutils

COPY main.sh /app/main.sh
RUN chmod +x /app/main.sh

RUN echo 'alias ll="ls -halp"' >> ~/.bashrc

WORKDIR /app

# Définissez des variables d'environnement avec des valeurs par défaut
ENV MQTT_BROKER_HOST=localhost \
    SLACK_WEBHOOK_URL= \
    MAX_SILENT_TOPICS=2 \
    WAIT_TIMEOUT=60 \
    CHECK_INTERVAL=3600 \
    TOPICS_FILE=/app/config/topics.txt \
    CREDENTIALS_FILE=/app/config/credentials.json \
    PROCESS_SCRIPT=/app/process.sh \
    DEBUG=false

CMD ["bash", "main.sh"]
