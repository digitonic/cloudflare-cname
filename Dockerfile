FROM ubuntu:16.04

ARG KUBE_VERSION="v1.10.3"

RUN apt-get update \
	&& apt-get -y install nano \
	&& apt-get -y install curl \
	&& apt-get auto-remove -qq -y \
	&& apt-get clean \
	&& curl -L -s https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
	&& chmod +x /usr/local/bin/kubectl \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add the application
COPY . /app
WORKDIR /app

RUN chmod +x /app/main.sh

ENTRYPOINT ["/app/main.sh"]