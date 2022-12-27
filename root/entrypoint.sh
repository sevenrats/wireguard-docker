#!/usr/bin/env bash

# Proxy signals
_term() { 
  echo "Caught SIGTERM signal!"
  wg-quick down wg0
  pkill -TERM tinyproxy
  pkill -TERM -P1
  exit 0
}

trap _term SIGTERM

# Up configuration
# TODO: configure resolv conf
# TODO: parse conf files and add up/down scripts.

# Run application
wg-quick up wg0 &
tinyproxy -dc /etc/tinyproxy/tinyproxy.conf &
wait -n ${!}