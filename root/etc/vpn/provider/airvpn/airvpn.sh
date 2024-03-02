_provider () {
    log "Begin AirVPN Provider"
    #devicename, apikey, portnumber
    API=$(echo "$1" | jq -r '.API')
    log "API: $API"
    DEVICE=$(echo "$1" | jq -r '.Device')
    log "DEVICE: $DEVICE"
    PORT=$(echo "$1" | jq -r '.Port')
    log "PORT: $PORT"
    
    all_servers=$(curl -s "https://airvpn.org/api/status/")

    # Don't connect to servers that we are already connected to
    readarray -t current_sessions <<< $(curl -s -H "API-KEY:${API}" "https://airvpn.org/api/userinfo/" | jq -r '.sessions[] | .server_location')
    available_servers=$(echo $all_servers | jq -r '.servers[]')
    for ((i = 0; i < ${#current_sessions[@]}; i++))
    do
        available_servers=$(echo $available_servers | jq -r --arg city "${current_sessions[$i]}" ' . | select(.location != $city)')
    done

    filtered_servers=$(echo $available_servers | jq -r '. | select(.health=="ok" and .currentload<25)| .ip_v4_in4+" "+.public_name' | tr '[:upper:]' '[:lower:]')
    log "Filtered server list: $filtered_servers"
    server="$(echo "$filtered_servers" | xargs -P 8 -I{} bash -c 'printServerLatency {}' | sort | head -1 | awk '{ print $2 }')"
    log "Selected server $server"
    conf=$(curl -s -H "API-KEY:${API}" "https://airvpn.org/api/generator/?protocols=wireguard_1_udp_1637&servers=$server&device=$DEVICE&wireguard_mtu=0&wireguard_persistent_keepalive=15&iplayer_exit=ipv4")
    log "Recording port $PORT"
    echo $PORT > /data/vpn/port.dat
    log "Writing conf to wg0: $conf"
    echo "$conf"
}