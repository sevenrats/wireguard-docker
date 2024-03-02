### A wireguard client sidecar designed to offer specific features:

1) automatic port forwarding configuration
    - forwarded ports are a core function of this client. it fails without a port.
2) automatic configuration and failover from a list clients
    - define a client according to its provider's schema:

        ```
        [{"Provider": "AirVPN",
        "API": "abcdefg",
        "Device": "WhatYouNamedIt",
        "Port": 12345},
        {"Provider": "PrivateInternetAccess",
        "User": "p1234567",
        "Password": "p@$$W0rD",
        "PrivateKey": <a wireguard private key>}]
        ```
    - The above list just needs to be made the contents of /data/vpn/bucket.conf within the container
    - The bucket.conf will be ignored if a wg0.conf exists
3) pluggable provider system
    - It should be possible to implement any provider that forwards ports. Check out the provider system code to see how.
    - the extensible system should be able to support all kinds of port leasing quackery.

4) a built-in, resilient public ip checker called fastip
5) tinyproxy built in and active by default on port 8888
6) pure bash entry loop
7) pretty small

#### Future Goals

- More providers
- Automatically make configurable http requests under certain conditions:
    - make a get or post when the ip or port changes
    - allow your tooling to listen for changes in realtime
- Automatically populate change data via the filesystem
    - your tooling can poll if it wants to
- Change endpoints on demand
    - would have to accept messaging of some kind.
    - probably filesystem based switch
- Evaluate the feasibility of implementing fastip in bash using xargs and ditching the C. It's kinda already implemented in this code, actually...

This container was made possible by the hard work of the team at LinuxServer.io, and is heavily based on their alpine-base and wireguard containers.