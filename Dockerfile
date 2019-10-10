FROM ubuntu:16.04

RUN apt-get update && \
	apt-get -y install nano && \
	apt-get -y install curl

# Add the application
COPY . /app
WORKDIR /app

RUN chmod +x /app/main.sh
RUN chmod +x /app/cloudflare_update_or_create.sh

ENTRYPOINT ["/app/main.sh"]