
log () {
    echo $(date) $1 >> /data/vpn/vpn.log
}

lookup_name() {
    log "BEGIN RESOLVE NAME"
    dns_servers=("1.1.1.1" "9.9.9.9" "8.8.8.8")
    for dns_server in "${dns_servers[@]}"; do
        output=$(drill @$dns_server $1)
        if [ $? -eq 0 ]; then
            log "SUCCESS lookup on $dns_server of $1"
            echo "$output" | awk '/IN\s+A/ {print $5}' | head -n 2 | tr -d '\n'
            return 0  # Return when any ping is successful
        else
            log "FAILED lookup on $dns_server of $1"
        fi
    done
    log "All lookups failed"
    return 1
}

_pia_get_token () {
    if [[ -z $PIA_USER || -z $PIA_PASS ]]; then
        echo "PIA GET TOKEN FAILURE"
        return 1
    fi
    piaIPAddress=$(lookup_name www.privateinternetaccess.com)
    generateTokenResponse=$(curl -s --location  \
    --resolve www.privateinternetaccess.com:443:$piaIPAddress \
    --request POST 'https://www.privateinternetaccess.com/api/client/v2/token' \
    --form "username=$PIA_USER" \
    --form "password=$PIA_PASS" )
    if [ "$(echo "$generateTokenResponse" | jq -r '.token')" == "" ]; then
        echo "PIA PARSE TOKEN RESPONSE FAILURE"
        return 1
    fi
    echo "$generateTokenResponse" | jq -r '.token'
    return 0
}

_pia_get_region () {

    MAX_LATENCY=${MAX_LATENCY:-0.08}
    export MAX_LATENCY

    serverlist_url='https://serverlist.piaservers.net/vpninfo/servers/v6'

    all_region_data=$(curl -s "$serverlist_url" | head -1)

    if [[ ${#all_region_data} -lt 1000 ]]; then
        return 1
    fi
    summarized_region_data="$( echo "$all_region_data" |
        jq -r '.regions[] | select(.port_forward==true) |
        .servers.meta[0].ip+" "+.id' )"
    selectedRegion="$(echo "$summarized_region_data" |
        xargs -P 8 -I{} bash -c 'printServerLatency {}' |
        sort | head -1 | awk '{ print $2 }')"
    regionData="$( echo "$all_region_data" |
    jq --arg REGION_ID "$selectedRegion" -r \
    '.regions[] | select(.id==$REGION_ID)')"
    if [[ -z $regionData ]]; then
        return 1
    fi
    echo "$regionData"
}

_bind_port () {
    echo "BINDING THE PORT"
    pfinfo=$(cat "/etc/vpn/.pfinfo")
    WG_HOSTNAME=$(echo $pfinfo | jq -r '.hostname')
    WG_GATEWAY=$(echo $pfinfo | jq -r '.gateway')
    payload=$(echo $pfinfo | jq -r '.payload')
    signature=$(echo $pfinfo | jq -r '.signature')
    bind_port_response="$(curl -Gs -m 5 \
        --connect-to "$WG_HOSTNAME::$WG_GATEWAY:" \
        --cacert "/etc/vpn/util/ca.rsa.4096.crt" \
        --data-urlencode "payload=${payload}" \
        --data-urlencode "signature=${signature}" \
        "https://$WG_HOSTNAME:19999/bindPort")"
    echo "BIND PORT RECEIVED RESPONSE:"
    echo $bind_port_response
    if [[ $(echo "$bind_port_response" | jq -r '.status') != "OK" ]]; then
        return 1
    else
        return 0
    fi
}

_pia_pf () {
    echo "PIA PORT FORWARD BEGIN"
    pfinfo=$(cat "/etc/vpn/.pfinfo")
    WG_HOSTNAME=$(echo $pfinfo | jq -r '.hostname')
    WG_GATEWAY=$(echo $pfinfo | jq -r '.gateway')
    TOKEN=$(echo $pfinfo | jq -r '.token')
    echo $WG_HOSTNAME
    echo $WG_GATEWAY
    echo $TOKEN
    payload_and_signature="$(curl -Gs \
        --connect-to "$WG_HOSTNAME::$WG_GATEWAY:" \
        --cacert "/etc/vpn/util/ca.rsa.4096.crt" \
        --data-urlencode "token=$TOKEN" \
        "https://${WG_HOSTNAME}:19999/getSignature")"
    if [[ $(echo "$payload_and_signature" | jq -r '.status') != "OK" ]]; then
        return 1
    else
        payload=$(echo "$payload_and_signature" | jq -r '.payload')
        PORT=$(echo "$payload" | base64 -d | jq -r '.port')
        signature=$(echo "$payload_and_signature" | jq -r '.signature')
        pfinfo=$(jq --null-input \
            --arg provider "PrivateInternetAccess" \
            --arg hostname "$WG_HOSTNAME" \
            --arg gateway "$WG_GATEWAY" \
            --arg payload "${payload}" \
            --arg signature "${signature}" \
            '{"provider": $provider, "hostname": $hostname, "gateway": $gateway, "payload": $payload, "signature": $signature}')
        echo $pfinfo > "/etc/vpn/.pfinfo"
        if _bind_port; then
            echo "BIND PORT SUCCESS"
            echo $PORT > "/connection/port.dat"
            return 0
        else
            echo "BIND PORT FAILURE"
            return 1
        fi
    fi
}



_connected () {
    # PIA overloads _connected so that it can hack in the initial bindport
    if ! $InitialPortForwardDone; then
        echo "PERFORMING INITIAL PORT FORWARD"
        if _pia_pf; then
            InitialPortForwardDone=true
            return 0
        else
            return 1
        fi
    else
        choices=( "amazon.com" "google.com" "facebook.com" "microsoft.com" )
        dns=$(cat $WG_CONFIG_PATH | grep "DNS" | cut -d " " -f 3)
        if [ ! -z "$dns" ]; then
            dns="1.1.1.1"
        fi
        if ping -c 1 -I wg0 $( tr -dc '[[:print:]]' <<< $dns) > /dev/null; then
            return 0
        else
            log "Main connectivity test failed. Performing full test."
            for choice in "${choices[@]}"
            do
                if curl --interface wg0 -s $choice > /dev/null; then
                    log "Full connectivity test successful. Not disconnected."
                    return 0
                fi
            done
            return 1
        fi
    fi
}

_provider () {
    PIA_USER=$(echo "$1" | jq -r '.User')
    PIA_PASS=$(echo "$1" | jq -r '.Password')
    PRIVATEKEY=$(echo "$1" | jq -r '.PrivateKey')
    PUBKEY=$(wg pubkey <<<${PRIVATEKEY})
    TOKEN=$(_pia_get_token)
    PIA_TOKEN_EXPIRATION=$(date +"%c" --date='1 day')
    regionData=$(_pia_get_region)
    WG_SERVER_IP=$(echo "$regionData" | jq -r '.servers.wg[0].ip')
    WG_HOSTNAME=$(echo "$regionData" | jq -r '.servers.wg[0].cn')
    wireguard_json="$(curl -Gs \
        --connect-to "$WG_HOSTNAME::$WG_SERVER_IP:" \
        --cacert "/etc/vpn/util/ca.rsa.4096.crt" \
        --data-urlencode "pt=${TOKEN}" \
        --data-urlencode "pubkey=$PUBKEY" \
        "https://$WG_HOSTNAME:1337/addKey" )"

    if [[ $(echo "$wireguard_json" | jq -r '.status') != "OK" ]]; then
        return 1
    fi
    # Server ip is the public ip, Gateway is the internal nexthop
    WG_GATEWAY=$(echo "$wireguard_json" | jq -r '.server_vip')
    address=$(echo "$wireguard_json" | jq -r '.peer_ip')
    dns=$(echo "$wireguard_json" | jq -r '.dns_servers[0]')
    privatekey=$PRIVATEKEY
    endpoint=${WG_SERVER_IP}:$(echo "$wireguard_json" | jq -r '.server_port')
    keepalive=25
    serverkey=$(echo "$wireguard_json" | jq -r '.server_key')
    allowedips=0.0.0.0/0
    pfinfo=$(jq --null-input \
        --arg provider "PrivateInternetAccess" \
        --arg hostname $WG_HOSTNAME \
        --arg gateway $WG_GATEWAY \
        --arg token $TOKEN \
        '{"provider": $provider, "hostname": $hostname, "gateway": $gateway, "token": $token }')
    echo $pfinfo > /etc/vpn/.pfinfo
    echo "$(_configure $address $privatekey $dns $keepalive $serverkey $endpoint $allowedips)"
}