#!/usr/bin/env bash

# Proxy Signals
sp_processes=("tinyproxy") # These are processes that will receive all signals that aren't overloaded
. ./signalproxy.sh

# Overload specific handlers if you want to
    # In this case lets overload all termination signals so that we can down wg0.
_term() { 
  echo "Caught a termination signal!"
  wg-quick down wg0
  pkill -TERM tinyproxy
}

trap _term SIGTERM
trap _term SIGINT
trap _term SIGQUIT
trap _term SIGHUP

# Configure stuff
    # e.g., ingest and template configs

#Launch App
wg-quick up wg0 &&
tinyproxy -dc /etc/tinyproxy/tinyproxy.conf & \
wait -n

