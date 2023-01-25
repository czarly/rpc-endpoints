#!/bin/bash

UPSTREAM_RPCS=$(docker run -e DEBIAN_FRONTEND=noninteractive bitnami/git:latest bash -c "git clone --quiet https://github.com/czarly/rpc-endpoints.git /endpoints && cd /endpoints && apt update -qq -y &> /dev/null && apt install -y -qq jq bc &> /dev/null && chmod +x generate_list.sh && ./generate_list.sh")
DSHACKLE_GRPC=http://127.0.0.1:2449

WHITELIST=$(curl ifconfig.me)

echo $UPSTREAM_RPCS

docker pull stakesquid/eth-proxy:latest

docker-compose up -d

