WG_CONFIG_PATH="/data/vpn/wg0.conf"
CONNECTED=false
CONFPATH=/data/vpn/bucket.conf

_bind_port () {
    # providers that require periodic port binding will overload this.
    # providers that don't can ignore it
    return 0
}

printServerLatency () {
    serverIP=$1
    regionID=$2
    time=$(LC_NUMERIC=en_US.utf8 curl -o /dev/null -s \
        --connect-timeout "5" \
        --write-out "%{time_connect}" \
        "https://$serverIP" | tr -d '"')
    if [ $time != "0.000000" ]; then
        #>&2 echo "Got latency ${time}s for region: $regionID"
        echo "$time $regionID"
    fi
}
export -f printServerLatency

_connected () {
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
}

_configure () {
    s=$(eval "
cat <<EOF
`cat /etc/vpn/util/peer.conf`
EOF")
    echo "$s"
}
export -f _configure

_healthcheck_vpn () {
    local interval=15 # tick tock
    local bindport_timer_reset=840
    local bindport_timer=$bindport_timer_reset
    while true;
    do
        sleep $interval
        if [ -f /walk ]; then
            rm -r /walk
            wg-quick down $WG_CONFIG_PATH
            CONNECTED=false
            until $CONNECTED
            do
                _connect
            done
        fi

        if [ $bindport_timer -gt 0 ]; then
            bindport_timer=$(($bindport_timer - $interval))
        else
            if _bind_port; then
                bindport_timer=$bindport_timer_reset
            else
                log "Bindport failed."
                CONNECTED=false
                wg-quick down $WG_CONFIG_PATH
                log "Restarting connection loop"
                until $CONNECTED
                do
                    _connect
                done
                #_connect
            fi
        fi

    done
    return 1
}

_connect () {
    # reset variables and overloaded functions
    . /etc/vpn/util/common.sh
    # read the vpn hint dictionary into an array
    readarray -t CONNECTIONS < <(cat $CONFPATH | jq -c '.[]')
    # select a random provider to get started
    CONNECTION=${CONNECTIONS[$(($RANDOM % ${#CONNECTIONS[@]}))]}
    # import that provider to overload necessary functions
    VPN_PROVIDER=$(echo "$CONNECTION" | jq -r '.Provider' | tr '[:upper:]' '[:lower:]')
    if [ -n "$VPN_PROVIDER" ]; then
        echo "The provider is $VPN_PROVIDER"
        provider_path="/etc/vpn/provider/${VPN_PROVIDER}"
        if [ -f $provider_path ]; then
            . $provider_path
        else
            echo "$VPN_PROVIDER is not a supported VPN provider."
            echo "Select from one of these:"
            echo
            echo "$(ls //etc/vpn/provider/)"
            exit
        fi
    else
        echo "Provider is undefined. I can't proceed."
    fi
    WG_CONFIG=$(_provider $CONNECTION)
    WG_CONFIG="${WG_CONFIG/"
[Peer]"/PostUp = DROUTE=\$(ip route | grep default | awk "'{print \$3}'"); HOMENET=192.168.0.0/16; HOMENET2=172.16.0.0/12; ip route add \$HOMENET2 via \$DROUTE; ip route add \$HOMENET via \$DROUTE;iptables -I OUTPUT -d \$HOMENET -j ACCEPT;iptables -A OUTPUT -d \$HOMENET2 -j ACCEPT; iptables -A OUTPUT ! -o %i -m mark ! --mark \$(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
PreDown = DROUTE=\$(ip route | grep default | awk "'{print \$3}'"); HOMENET=192.168.0.0/16; HOMENET2=172.16.0.0/12; ip route del \$HOMENET2 via \$DROUTE; ip route del \$HOMENET via \$DROUTE; iptables -D OUTPUT ! -o %i -m mark ! --mark \$(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT; iptables -D OUTPUT -d \$HOMENET -j ACCEPT; iptables -D OUTPUT -d \$HOMENET2 -j ACCEPT

[Peer]}"
    echo "$WG_CONFIG" > $WG_CONFIG_PATH
    wg-quick up $WG_CONFIG_PATH
    sleep 5
    if ! _connected; then
        #sleep infinity
        log "CONNECTION FAILURE"
        #wg-quick down wg0
        return 1
    else
        ln -s /connection/port.dat /data/vpn/port.dat # temporary solution while we migrate to new connection data location
        fastip > /connection/ip.dat
        CONNECTED=true
        log "CONNECTION SUCCESS!"
        #iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
        return 0
    fi
}

log () {
    echo $(date) $1 >> /data/vpn/vpn.log
}
export -f log

init_firewall () { #not currently used
    log "Initializing firewall."
    iptables -F
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT
    iptables -A INPUT -s 172.16.0.0/12 -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT

    DROUTE=$(ip route | grep default | awk "'{print $3}'")
    ip route add 192.168.0.0/16 via $DROUTE
    ip route add 172.16.0.0/12 via $DROUTE
}
