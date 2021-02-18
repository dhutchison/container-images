#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

function create_service_file {

  local name=$1
  local accessory_category=$2
  local mac_address=$3
  local port=$4
  local setup_id=$5

     # Write the service configurtion file to the current directory
cat <<EOF > "${name}.service"
<service-group>
  <name>$name</name>
  <service>
    <type>_hap._tcp</type>
    <port>$port</port>

    <!-- friendly name -->
    <txt-record>md=$name</txt-record>

    <!-- HAP version -->
    <txt-record>pv=1.0</txt-record>
    <!-- MAC -->
    <txt-record>id=${mac_address}</txt-record>
    <!-- Current configuration number -->
    <txt-record>c#=2</txt-record>

    <!-- accessory category -->
    <txt-record>ci=${accessory_category}</txt-record>

    <!-- accessory state
          This must have a value of 1 -->
    <txt-record>s#=1</txt-record>
    <!-- Pairing Feature Flags
         nothing to configure -->
    <txt-record>ff=0</txt-record>
    <!-- Status flags
         0=not paired, 1=paired -->
    <txt-record>sf=1</txt-record>
    <!-- setup hash (used for pairing).
         Required to support enhanced
         setup payload information (but
         not defined in the spec)        -->
    <txt-record>sh=$(echo -n ${setup_id}${mac_address} | openssl dgst -binary -sha512 | head -c 4 | base64)</txt-record>
  </service>
</service-group>
EOF

  # Move it in to place
  sudo mv -i "${name}.service" "/etc/avahi/services/${name// /}.service"

  # Helper Message
  echo "Please ensure you have exposed port $port"

}

# Find the running homebridge container
CONTAINER=$(sudo docker ps | grep homebridge | cut -d " " -f1)


if [ -z "$CONTAINER" ]; then
  echo "No running homebridge container found"
  exit 1
fi

# Get configuration values out of the container configuration file
CONFIG=$(sudo docker exec "$CONTAINER" cat /homebridge/config.json)
NAME=$(echo "$CONFIG" | jq -r .bridge.name)
MAC=$(echo "$CONFIG" | jq -r .bridge.username)
PORT=$(echo "$CONFIG" | jq -r .bridge.port)

ACCESSORY_CONFIG=$(sudo docker exec "$CONTAINER" cat /homebridge/persist/AccessoryInfo.${MAC//:/}.json)
SETUPID=$(echo "$ACCESSORY_CONFIG" | jq -r .setupID)
CATEGORY=$(echo "$ACCESSORY_CONFIG" | jq -r .category)

# accessory category 2=bridge
create_service_file "$NAME" $CATEGORY "$MAC" "$PORT" "$SETUPID"


# Extra accessory files
# Exclude the one for the bridge
ACCESSORY_FILES=$(sudo docker exec "$CONTAINER" find persist/ -name 'AccessoryInfo.*.json' | grep -v ${MAC//:/})

# Save current IFS
SAVEIFS=$IFS
# Change IFS to new line
IFS=$'\n'
# split to array $names
ACCESSORY_FILES=($ACCESSORY_FILES)
# Restore IFS
IFS=$SAVEIFS

for i in "${ACCESSORY_FILES[@]}"
do
  echo "File is $i"

  ACCESSORY_CONFIG=$(sudo docker exec "$CONTAINER" cat /homebridge/$i)
  SETUPID=$(echo "$ACCESSORY_CONFIG" | jq -r .setupID)
  CATEGORY=$(echo "$ACCESSORY_CONFIG" | jq -r .category) 
  NAME=$(echo "$ACCESSORY_CONFIG" | jq -r .displayName)
  MAC=$(echo "$i" | cut -d. -f2 | sed 's/\(..\)/\1:/g;s/:$//')
  PORT=$(sudo docker logs "$CONTAINER" | grep "${NAME} is running on port" | tail -n 1 | awk -F ' ' '{print $NF}' | cut -d. -f1)

  create_service_file "$NAME" $CATEGORY "$MAC" "$PORT" "$SETUPID"

done



