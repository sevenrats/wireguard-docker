This alpine-based wireguard client container is 50 megabytes and includes s6-overlay, tinyproxy running on port 8888, and a reliable ip checker called fastip.

While config ingestion is under construction, please mount your config directory directly into /etc/wireguard and define your vpn DNS in your docker up command.

If you would like to use your custom tinyproxy config, mount it over the default one at /etc/tinyproxy/tinyproxy.conf

It is advisable to manually modify the tinyproxy configuration to deny access from the VPN adapter until a script is implemented to do so.

This container was made possible by the hard work of the team at LinuxServer.io, and is heavily based on their alpine-base and wireguard containers.
