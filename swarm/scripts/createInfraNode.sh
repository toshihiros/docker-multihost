#!/bin/bash
# Creates infra node if needed
if [ $AWS_ACCESS_KEY_ID ]; then
  # Check if the node already exists
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' registry-aws):5000
  if ! docker-machine inspect infra-aws &> /dev/null; then
    printf "\e[33m*** \e[32mCreating infra node into AWS \e[33m***\e[0m\n"
    docker-machine create -d amazonec2 --engine-insecure-registry=$REGISTRY infra-aws
  fi
  eval $(docker-machine env infra-aws)
  ADVERTISE_IP=$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' infra-aws)
else
  REGISTRY=$(docker-machine ip registry):5000
  if ! docker-machine inspect infra &> /dev/null; then
    printf "\e[33m*** \e[32mCreating infra node locally \e[33m***\e[0m\n"
    docker-machine create -d virtualbox --engine-insecure-registry=$REGISTRY infra
  fi
  eval $(docker-machine env infra)
  ADVERTISE_IP=$(docker-machine ip infra)
fi
# Start Consul if not already running
if ! docker inspect consul &> /dev/null; then
  printf "\e[33m*** \e[32mStarting consul container \e[33m***\e[0m\n"
  docker run -d -p 8500:8500 --name consul $REGISTRY/consul -server -bootstrap-expect 1
else
  printf "\e[33m*** \e[32mConsul already running \e[33m***\e[0m\n"
fi
