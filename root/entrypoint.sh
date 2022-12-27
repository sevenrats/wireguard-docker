#!/usr/bin/env bash

# Proxy signals
_term() { 
  echo "Caught SIGTERM signal!"
  wg-quick down wg0
  pkill tinyproxy
  pkill -TERM -P1
  exit 0
}

trap _term SIGTERM

# Run application
wg-quick up wg0 &
tinyproxy -dc /etc/tinyproxy/tinyproxy.conf &
wait -n ${!}