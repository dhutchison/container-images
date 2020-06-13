#!/bin/bash

# The name of the network the docker container will be connected to
DOCKER_NETWORK=traefik-backend

# Find the subnet for the docker network
subnet=$(docker network inspect "$DOCKER_NETWORK" | jq --raw-output .[0].IPAM.Config[0].Subnet)

if [ ! -z subnet ]; then

    echo "Got subnet $subnet"

    # Find the network interface
    interface=$(ip route | grep "$subnet" | cut -d ' ' -f3)

    if [ ! -z interface ]; then
        echo "Got interface $interface"

        # Check the setting value to check we are substituting correctly
        sudo sysctl -w net.ipv4.conf.${interface}.bc_forwarding=1
    else
        echo "Could not determine the network interface for $subnet"
    fi
else
    echo "Could not determine the subnet for $DOCKER_NETWORK"
fi

# Disable the setting to ignore echo broadcasts
sudo sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0
# Enabling broadcast forwarding for "all" interfaces, 
# although it seems this needs used in combination with specific interfaces
sudo sysctl -w net.ipv4.conf.all.bc_forwarding=1