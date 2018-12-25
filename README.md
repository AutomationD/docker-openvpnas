# OpenVPN Access Server
**With Duo Security 2-factor authentication**

This image incorporates OpenVPN Access Server with Duo Security 2 factor auth.
All configuration is done via environment variables, for example:
`OPENVPN_VPN__DAEMON__0__LISTEN__IP_ADDRESS` is mapped to `vpn.daemon.0.listen.ip.address`, which is searched in present configuration files (as.conf and config.json), which is set to a value of an env var.

Duo Security is optional but is highly recommended, since basic account is free. All you need to do is get api credentials and enable post-auth script.

## Run examples
*Host Mode (recommended)*

Ensure to set your host's interface name
```
docker run \
    --cap-add=NET_ADMIN \
    --device /dev/net/tun:/dev/net/tun \
    -v ${PWD}/db:/usr/local/openvpn_as/etc/db \
    --network=host \
    -e OPENVPN_ADMIN_UI__HTTPS__IP_ADDRESS="eth0" \
    -e OPENVPN_CS__HTTPS__IP_ADDRESS="eth0" \
    -e OPENVPN_VPN__DAEMON__0__LISTEN__IP_ADDRESS="eth0" \
    -e OPENVPN_VPN__DAEMON__0__SERVER__IP_ADDRESS="eth0" \
    -e OPENVPN_HOST__NAME="localhost" \
-it kireevco/openvpnas
```

*NAT Mode*
```
docker run \
    --cap-add=NET_ADMIN \
    --device /dev/net/tun:/dev/net/tun \
    -v ${PWD}/db:/usr/local/openvpn_as/etc/db \
    -p "943:943/tcp" \
    -e OPENVPN_ADMIN_UI__HTTPS__IP_ADDRESS="eth0" \
    -e OPENVPN_CS__HTTPS__IP_ADDRESS="eth0" \
    -e OPENVPN_VPN__DAEMON__0__LISTEN__IP_ADDRESS="eth0" \
    -e OPENVPN_VPN__DAEMON__0__SERVER__IP_ADDRESS="eth0" \
    -e OPENVPN_HOST__NAME="localhost" \
-it kireevco/openvpnas
```

## Duo Security
### 1. Get a Duo Security account
### 2. Ensure to set the following env vars:
```
-e OPENVPN_DUO_INTEGRATION_KEY="<get-from-duo>"
-e OPENVPN_DUO_SECRET_KEY="<get-from-duo>"
-e OPENVPN_DUO_API_HOSTNAME="<get-from-duo>"
-e OPENVPN_AUTH__MODULE__POST_AUTH_SCRIPT=/usr/local/openvpn_as/scripts/duo_openvpn_as.py"
```

